import 'e_string3.dart';
import 'estrange.dart';

/// @author jd


extension TestString1 on String {
  void log1() {
    print("项目内日志1");
    "3".log3();
    Estrange().log();
  }
}