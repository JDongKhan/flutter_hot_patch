// ===== EventChannel：flutter/services 同名镜像（flutter.js 值类区）=====
//
// `receiveBroadcastStream([args])` → 运行时 `StreamController.broadcast`：
//   onListen（首个订阅者）→ 宿主通道 eventChannelListen（注册订阅 + JS 回调句柄）
//   onCancel（订阅者归零）→ 宿主通道 eventChannelCancel
// 宿主把原生事件按 `['data', v]` / `['error', msg]` / `['done']` 回传，
// JS 侧转成 Stream 的 `add` / `addError` / `close`。
//
// 订阅是**有状态租约**（与 Controller 同类）：回调句柄按 page scope 登记，
// 页面销毁时随 `__closeRoot` 释放，release 钩子同步取消宿主订阅，不留悬挂流。
const String eventChannelJsSource = r'''
  // ----- EventChannel -------------------------------------------------------

  var __eventSubSeq = 0;
  // subId → { ctl, handleId }。宿主只认 subId，不返回句柄（构造保持同步）。
  var __eventSubs = {};

  export class EventChannel {
    constructor(args) {
      this.name = (args && args.name !== undefined) ? args.name : '';
      var codec = args && args.codec;
      this.codec = (codec && codec.__codec) ? codec.__codec : 'standard';
    }
    receiveBroadcastStream(args) {
      var self = this;
      // 跨补丁重载唯一：仅靠自增序号会在模块重新求值后与宿主旧租约撞号。
      var subId = 'evsub' + Date.now().toString(36) + '_' + (++__eventSubSeq);
      var ctl = StreamController.broadcast({
        onListen: function () {
          var sub = __eventSubs[subId];
          if (!sub) { return; }
          G._app_host_.invoke(
            'eventChannelListen',
            [subId, self.name, self.codec, args, sub.handleId]
          ).catch(function (e) { __error('EventChannel.listen: ' + String(e)); });
        },
        onCancel: function () {
          G._app_host_.invoke(
            'eventChannelCancel', [subId]
          ).catch(function (e) { __error('EventChannel.cancel: ' + String(e)); });
        }
      });
      // 回调句柄随页面释放；release 里同步取消宿主订阅（幂等）。
      var handleId = G.__core.__registerHandle(function (kind, payload) {
        var sub = __eventSubs[subId];
        if (!sub) { return; }
        if (kind === 'data') {
          sub.ctl.add(payload);
        } else if (kind === 'error') {
          sub.ctl.addError(payload);
        } else {
          sub.ctl.close();
          delete __eventSubs[subId];
        }
      }, 'fn', {
        scope: 'page',
        sync: false,
        release: function () {
          G._app_host_.invoke(
            'eventChannelCancel', [subId]
          ).catch(function (e) { __error('EventChannel.release: ' + String(e)); });
          delete __eventSubs[subId];
        }
      });
      __eventSubs[subId] = { ctl: ctl, handleId: handleId };
      return ctl.stream;
    }
  }
''';
