import 'package:moor/moor_web.dart';

import '../db.dart';

MyDatabase constructDb({bool logStatements = false}) {
  return MyDatabase(WebDatabase('db', logStatements: logStatements));
}