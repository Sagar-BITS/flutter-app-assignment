import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

class Employee extends ParseObject implements ParseCloneable {
  static const String _keyTableName = 'Employee';
  
  Employee() : super(_keyTableName);
  Employee.clone() : this();

  @override
  Employee clone(Map<String, dynamic> map) => Employee.clone()..fromJson(map);

  // Getters
  String get name => get<String>('name') ?? '';
  String get email => get<String>('email') ?? '';
  String get position => get<String>('position') ?? '';
  double get salary {
    final value = get('salary');
    if (value == null) return 0.0;
    return value is int ? value.toDouble() : value;
  }
  String get id => objectId ?? '';

  // Setters
  set name(String value) => set<String>('name', value);
  set email(String value) => set<String>('email', value);
  set position(String value) => set<String>('position', value);
  set salary(double value) => set<double>('salary', value);
}


