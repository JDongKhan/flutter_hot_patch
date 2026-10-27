import 'package:flutter/cupertino.dart';

import 'package:hot_module_base/hot_module_base.dart';

/// @author jd
class NetworkVm extends ChangeNotifier {
  Future<Map> loadUserInfo({dynamic params}) async {
    dynamic data = await Network.post(url: "loadUserInfo", params: params);
    print("获取数据:$data");
    return data;
  }
}
