import 'package:flutter/cupertino.dart';

import '../base/network.dart';

/// @author jd
class NetworkVm  extends ChangeNotifier{

  Future<Map> loadUserInfo({dynamic params}) {
    return Network.post(params: params);
  }
}

