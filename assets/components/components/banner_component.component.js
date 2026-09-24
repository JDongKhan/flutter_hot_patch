// GENERATED CODE - DO NOT EDIT
// 由 ui_component_generator 从 lib/components/banner_component.dart 自动生成
// 重新生成：dart run build_runner build


export class BannerCard {
  constructor() {
    this._views = 0;
  }
  initState() { this._views = 5; }
  bump() { this.setState(function(){ this._views += 1; }); }
  build() {
      return {
      "type": "Column",
      "children": [
        {
          "type": "Text",
          "props": {
            "data": "Banner from another file",
            "style": {
              "fontSize": 20,
              "color": '#009688'
            }
          }
        },
        {
          "type": "Text",
          "props": {
            "data": "views = " + this._views
          }
        },
        {
          "type": "Button",
          "props": {
            "kind": "elevated",
            "label": "Bump",
            "event": "bump"
          }
        }
      ]
    };
  }
}

