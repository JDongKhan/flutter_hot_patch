import 'package:ui_component/ui_component.dart';

/// @author jd

class Network {
  @HostInjected()
  static Future<Map> post({dynamic params}) {
    print("开始网络请求");
    return Future.delayed(Duration(seconds: 1), () {
      print("网络请求结束");
      return {"data": params, "code": 200, "message": "success"};
    });
  }
}
