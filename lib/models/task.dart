import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

class Task extends ParseObject implements ParseCloneable {
  Task() : super(_keyTableName);
  Task.clone() : this();

  static const String _keyTableName = 'Task';

  @override
  Task clone(Map<String, dynamic> map) => Task.clone()..fromJson(map);

  String? get title => get<String>('title');
  set title(String? value) => set<String>('title', value!);

  String? get description => get<String>('description');
  set description(String? value) => set<String>('description', value!);

  String? get status => get<String>('status');
  set status(String? value) => set<String>('status', value!);

  DateTime? get dueDate => get<DateTime>('dueDate');
  set dueDate(DateTime? value) => set<DateTime>('dueDate', value!);

  ParseUser? get owner => get<ParseUser>('owner');
  set owner(ParseUser? user) => set<ParseUser>('owner', user!);

  bool get isDone => get<bool>('isDone') ?? false;
  set isDone(bool value) => set<bool>('isDone', value);
}
