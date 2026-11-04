import 'dart:async';

import 'package:flutter/material.dart';

/// 日志级别（仅用于控制台着色，不参与采集判定）。
enum AppLogLevel { info, warn, error }

/// 一条日志：采集时间 + 原始文本 + 由文本推导的级别。
@immutable
class AppLogRecord {
  const AppLogRecord({
    required this.time,
    required this.text,
    required this.level,
  });

  final DateTime time;
  final String text;
  final AppLogLevel level;
}

/// 日志收集中心：捕获 App 运行期的全部日志。
///
/// 采集口径（两路都汇到这里）：
///   - Dart 侧 `print`：由 [installLogCapture] 中的 zone `print` 钩子捕获；
///   - Dart 侧 `debugPrint`（Flutter 框架 / hot_patch 的 HotPatchLog 都走它）：
///     由 [installLogCapture] 统一改写成 `print`，进入同一条通道；
///   - JS 侧 `print` / `debugPrint`：经运行时 `log` 通道 → HotPatchLog → `debugPrint`，
///     同样落到上面的通道，无需额外接线。
class AppLogCenter extends ChangeNotifier {
  AppLogCenter._();

  static final AppLogCenter instance = AppLogCenter._();

  /// 最多保留的条数（超出丢弃最旧的，避免长时间挂机无限增长）。
  static const int maxRecords = 1000;

  final List<AppLogRecord> _records = <AppLogRecord>[];

  List<AppLogRecord> get records => List.unmodifiable(_records);

  bool _notifyScheduled = false;

  /// 追加一条日志（任意线程/回调时机都安全：通知会延后到帧末）。
  void add(String text) {
    _records.add(AppLogRecord(time: DateTime.now(), text: text, level: _levelOf(text)));
    if (_records.length > maxRecords) {
      _records.removeRange(0, _records.length - maxRecords);
    }
    _scheduleNotify();
  }

  void clear() {
    if (_records.isEmpty) return;
    _records.clear();
    notifyListeners();
  }

  /// 延迟到帧末通知：日志可能来自 build 过程（如 build 内的 print），
  /// 同步 notify 会触发「setState called during build」。
  void _scheduleNotify() {
    if (_notifyScheduled) return;
    _notifyScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notifyScheduled = false;
      notifyListeners();
    });
    // 空闲（没有帧在进行）时也要让 post-frame 回调有机会执行。
    WidgetsBinding.instance.scheduleFrame();
  }

  /// 从日志文本推导级别：hot_patch 的 warn/error 前缀可直接识别，其余按 info。
  static AppLogLevel _levelOf(String text) {
    if (text.contains('[ERROR]')) return AppLogLevel.error;
    if (text.contains('[WARN]') || text.contains('[WARNING]')) return AppLogLevel.warn;
    return AppLogLevel.info;
  }
}

/// 装配日志捕获：改写 `debugPrint` 走 `print`，配合 [appLogZoneSpecification] 的
/// `print` 钩子把全部输出收进 [AppLogCenter]。**在 runZoned 之前调用一次**。
void installLogCapture() {
  // ignore: avoid_print - 日志统一走 print，由下面的 zone 钩子捕获。
  debugPrint = (String? message, {int? wrapWidth}) => print(message ?? '');
}

/// 捕获 `print` 的 Zone 配置：先入库，再照常输出到终端（不改变原日志行为）。
final ZoneSpecification appLogZoneSpecification = ZoneSpecification(
  print: (self, parent, zone, line) {
    AppLogCenter.instance.add(line);
    parent.print(zone, line);
  },
);

/// 右侧日志控制台（固定宽度由调用方约束，当前为 300）。
class AppLogConsole extends StatefulWidget {
  const AppLogConsole({super.key});

  @override
  State<AppLogConsole> createState() => _AppLogConsoleState();
}

class _AppLogConsoleState extends State<AppLogConsole> {
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    AppLogCenter.instance.addListener(_onLogsChanged);
  }

  @override
  void dispose() {
    AppLogCenter.instance.removeListener(_onLogsChanged);
    _scroll.dispose();
    super.dispose();
  }

  void _onLogsChanged() {
    if (!mounted) return;
    setState(() {});
    // 新日志到达后吸到底部（在列表完成布局后再滚动）。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.jumpTo(_scroll.position.maxScrollExtent);
    });
  }

  @override
  Widget build(BuildContext context) {
    final records = AppLogCenter.instance.records;
    return Material(
      color: const Color(0xFF1C1F24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(records.length),
          const Divider(height: 1, thickness: 1, color: Color(0xFF2C3038)),
          Expanded(child: _buildList(records)),
        ],
      ),
    );
  }

  Widget _buildHeader(int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      child: Row(
        children: [
          const Icon(Icons.terminal, size: 16, color: Color(0xFF8AB4F8)),
          const SizedBox(width: 6),
          const Text(
            '日志控制台',
            style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 8),
          Text('($count)', style: const TextStyle(color: Color(0xFF9AA0A6), fontSize: 11)),
          const Spacer(),
          IconButton(
            // 控制台在 Navigator 外层，没有 Overlay 祖先，故不使用 tooltip。
            iconSize: 16,
            visualDensity: VisualDensity.compact,
            color: const Color(0xFF9AA0A6),
            onPressed: AppLogCenter.instance.clear,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<AppLogRecord> records) {
    if (records.isEmpty) {
      return const Center(
        child: Text('暂无日志', style: TextStyle(color: Color(0xFF9AA0A6), fontSize: 12)),
      );
    }
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      itemCount: records.length,
      itemBuilder: (context, index) {
        final r = records[index];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          // 控制台在 Navigator 外层（没有 Overlay），不能用 SelectableText
          //（点击时它需要 Overlay 弹选择手柄，会直接抛断言），故用普通 Text。
          child: Text(
            '${_formatTime(r.time)} ${r.text}',
            style: TextStyle(
              color: _colorOf(r.level),
              fontSize: 11,
              height: 1.35,
              fontFamily: 'Menlo',
              fontFamilyFallback: const ['Courier', 'monospace'],
            ),
          ),
        );
      },
    );
  }

  static Color _colorOf(AppLogLevel level) => switch (level) {
        AppLogLevel.error => const Color(0xFFFF8A80),
        AppLogLevel.warn => const Color(0xFFFFD180),
        AppLogLevel.info => const Color(0xFFE8EAED),
      };

  static String _formatTime(DateTime time) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(time.hour)}:${two(time.minute)}:${two(time.second)}.'
        '${time.millisecond.toString().padLeft(3, '0')}';
  }
}
