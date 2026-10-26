// ===== 基础组件：JSON → IconData =====
//
// 图标名 → Material Icons 的映射表（表大且增长快，故独立成文件）。
import 'package:flutter/material.dart';

import '../../../utils/hot_patch_log.dart';

/// JSON → IconData（'add'/'star'/...；未命中回退 Icons.circle）。
IconData iconFromJson(Object? v) {
  final name = v is String ? v : '';
  final icon = _icons[name];
  if (icon == null) {
    HotPatchLog.warn('iconFromJson: 未注册的 Icons.$name，回退 Icons.circle');
    return Icons.circle;
  }
  return icon;
}

/// 常用 Material Icons 映射表（按需扩展；未命中回退 circle）。
const Map<String, IconData> _icons = {
  'add': Icons.add,
  'add_circle': Icons.add_circle,
  'article': Icons.article,
  'arrow_back': Icons.arrow_back,
  'arrow_forward': Icons.arrow_forward,
  'arrow_drop_down': Icons.arrow_drop_down,
  'arrow_downward': Icons.arrow_downward,
  'arrow_upward': Icons.arrow_upward,
  'check': Icons.check,
  'check_box': Icons.check_box,
  'check_box_outline_blank': Icons.check_box_outline_blank,
  'check_circle': Icons.check_circle,
  'chevron_left': Icons.chevron_left,
  'chevron_right': Icons.chevron_right,
  'close': Icons.close,
  'create': Icons.create,
  'date_range': Icons.date_range,
  'delete': Icons.delete,
  'edit': Icons.edit,
  'email': Icons.email,
  'error': Icons.error,
  'exit_to_app': Icons.exit_to_app,
  'explore': Icons.explore,
  'extension': Icons.extension,
  'face': Icons.face,
  'favorite': Icons.favorite,
  'favorite_border': Icons.favorite_border,
  'feedback': Icons.feedback,
  'filter_list': Icons.filter_list,
  'flag': Icons.flag,
  'folder': Icons.folder,
  'home': Icons.home,
  'info': Icons.info,
  'keyboard_arrow_down': Icons.keyboard_arrow_down,
  'launch': Icons.launch,
  'list': Icons.list,
  'location_on': Icons.location_on,
  'lock': Icons.lock,
  'lock_open': Icons.lock_open,
  'mail': Icons.mail,
  'menu': Icons.menu,
  'mic': Icons.mic,
  'more_vert': Icons.more_vert,
  'notifications': Icons.notifications,
  'pause': Icons.pause,
  'person': Icons.person,
  'phone': Icons.phone,
  'play_arrow': Icons.play_arrow,
  'refresh': Icons.refresh,
  'search': Icons.search,
  'send': Icons.send,
  'settings': Icons.settings,
  'share': Icons.share,
  'shopping_cart': Icons.shopping_cart,
  'star': Icons.star,
  'star_border': Icons.star_border,
  'thumb_up': Icons.thumb_up,
  'verified': Icons.verified,
  'visibility': Icons.visibility,
  'visibility_off': Icons.visibility_off,
  'volume_down': Icons.volume_down,
  'volume_up': Icons.volume_up,
  'warning': Icons.warning,
  'wifi': Icons.wifi,
  'height': Icons.height,
  'arrow_right': Icons.arrow_right,
  'build': Icons.build,
  'center_focus_strong': Icons.center_focus_strong,
  'straighten': Icons.straighten,
  'tune': Icons.tune,
  'widgets_outlined': Icons.widgets_outlined,
  'compare_arrows': Icons.compare_arrows,
  'drag_handle': Icons.drag_handle,
};
