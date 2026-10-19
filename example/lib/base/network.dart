import 'package:hot_patch_annotations/hot_patch_annotations.dart';

/// @author jd

class Network {
  @HostInjected()
  static Future<Map> post({required String url,dynamic params}) {
    print("开始网络请求:$url");
    return Future.delayed(Duration(seconds: 1), () {
      print("网络请求结束:$url");
      return {"data": params, "code": 200, "message": "success"};
    });
  }
}
