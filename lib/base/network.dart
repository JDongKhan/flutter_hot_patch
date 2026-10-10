import 'package:ui_component/ui_component.dart';

/// @author jd

class Network {
  @HostInjected()
  static Future<Map> post({dynamic params}) {
    return Future.delayed(Duration(seconds: 1), () {
      return {"data": params, "code": 200, "message": "success"};
    });
  }
}
