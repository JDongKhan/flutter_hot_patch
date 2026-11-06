// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/components/grammar/inheritance_detail.dart 自动生成
// 重新生成：dart run build_runner build

import { Colors, Column, CrossAxisAlignment, FontWeight, SizedBox, StatelessWidget, Text, TextStyle } from '../../flutter.js';

// 模型 BaseVehicle
export class BaseVehicle {
  constructor() {
    this.wheels = 4;
  }
  get speed() {
    return 60;
  }
  describe() {
    return (this.speed + 10);
  }
}

// 模型 SportCar
export class SportCar extends BaseVehicle {
  constructor(args) {
    super(args);
  }
  get speed() {
    return (super.speed + 20);
  }
  report() {
    return ((this.wheels * 10) + super.describe());
  }
}

// 模型 Greeting
export class Greeting {
  constructor(args) {
    this.__applyProps(args);
  }
  __applyProps(args) {
    this.name = (args && args.name !== undefined) ? args.name : '';
  }
  greet() {
    return "Hello, " + this.name;
  }
  describe() {
    return "Greeting(" + this.name + ")";
  }
}

// 模型 FancyGreeting
export class FancyGreeting extends Greeting {
  constructor(args) {
    super(args);
    this.emoji = "✨";
  }
  greet() {
    return super.greet() + " " + this.emoji;
  }
  describe() {
    return super.describe() + " → FancyGreeting";
  }
}

// 组件 InheritanceDetail
export class InheritanceDetail extends StatelessWidget {
  constructor(args) {
    super(args);
  }
  build(context) {
    const plain = new Greeting({
      "name": "Dart"
    });
    const fancy = new FancyGreeting({
      "name": "JS"
    });
    const car = new SportCar({});
    return new Column({
      "crossAxisAlignment": CrossAxisAlignment.stretch,
      "children": [
        (this.__k0 || (this.__k0 = new Text({
          "data": "普通类单继承（extends / super / 多态）",
          "style": new TextStyle({
            "fontSize": 16,
            "fontWeight": FontWeight.bold
          })
        }))),
        (this.__k1 || (this.__k1 = new SizedBox({
          "height": 8
        }))),
        (this.__k2 || (this.__k2 = new Text({
          "data": "Greeting 为基类，FancyGreeting 覆盖 greet / describe 并调用 super。",
          "style": new TextStyle({
            "fontSize": 13,
            "color": Colors.black54
          })
        }))),
        (this.__k3 || (this.__k3 = new SizedBox({
          "height": 12
        }))),
        new Text({
          "style": (this.__k4 || (this.__k4 = new TextStyle({
            "fontSize": 15
          }))),
          "data": plain.greet()
        }),
        new Text({
          "style": (this.__k5 || (this.__k5 = new TextStyle({
            "fontSize": 13
          }))),
          "data": plain.describe()
        }),
        (this.__k1 || (this.__k1 = new SizedBox({
          "height": 8
        }))),
        new Text({
          "style": (this.__k4 || (this.__k4 = new TextStyle({
            "fontSize": 15
          }))),
          "data": fancy.greet()
        }),
        new Text({
          "style": (this.__k5 || (this.__k5 = new TextStyle({
            "fontSize": 13
          }))),
          "data": fancy.describe()
        }),
        (this.__k3 || (this.__k3 = new SizedBox({
          "height": 12
        }))),
        new Text({
          "style": (this.__k5 || (this.__k5 = new TextStyle({
            "fontSize": 13
          }))),
          "data": "父类成员：speed=" + car.speed + " / report=" + car.report()
        })
      ]
    });
  }
}

