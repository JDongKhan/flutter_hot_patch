// GENERATED CODE - DO NOT EDIT
// 由 ui_component_generator 从 lib/components/reorder_list.dart 自动生成
// 重新生成：dart run build_runner build

import { __h } from '../flutter.js';

// 组件 ReorderListDemo
export class ReorderListDemo {
  constructor() {
    this._items = ["北京", "上海", "广州", "深圳", "杭州", "成都"];
  }
  _onReorder(oldIndex, newIndex) {
    console.log(__str(oldIndex) + " - " + __str(newIndex));
    this.setState(function(){ var item = this._items.splice(oldIndex, 1)[0]; var target = ((newIndex > oldIndex) ? (newIndex - 1) : newIndex); this._items.splice(target, 0, item); });
  }
  _add() {
    this.setState(function(){ this._items.push("城市 " + (this._items.length + 1)); });
  }
  build(context) {
    return __h('Column', {
        "mainAxisSize": "min"
      }, [
        __h('Padding', {
            "padding": {
              "left": 12.0,
              "top": 12.0,
              "right": 12.0,
              "bottom": 12.0
            }
          }, [
            __h('Row', {}, [
                __h('Expanded', {}, [
                    __h('Text', {
                        "data": "长按拖拽调整顺序（onReorder 双参事件）",
                        "style": {
                          "fontSize": 13,
                          "color": '#9E9E9E'
                        }
                      })
                  ]),
                __h('Button', {
                    "kind": "elevated",
                    "label": "添加",
                    "event": this.__bind("_add")
                  })
              ])
          ]),
        __h('SizedBox', {
            "height": 320
          }, [
            __h('ReorderableListView', {
                "event": this.__bind("_onReorder"),
                "padding": {
                  "left": 12.0,
                  "top": 0.0,
                  "right": 12.0,
                  "bottom": 0.0
                }
              }, [
                ...(() => { var out = []; for (let item of this._items) { out.push.apply(out, [__h('Card', { "key": new ValueKey(item) }, [ __h('ListTile', { "title": item, "leading": __h('Icon', { "icon": "drag_handle" }) }) ])]); } return out; })()
              ])
          ])
      ]);
  }
}

