import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import '../models/task.dart';

class TaskService {
  // Fetch all tasks from Back4App
  Future<List<Task>> getTasks() async {
    final query = QueryBuilder<Task>(Task())..orderByDescending('createdAt');
    final response = await query.query();

    if (response.success && response.results != null) {
      return response.results!.map((task) => task as Task).toList();
    } else {
      throw Exception('Failed to fetch tasks: ${response.error?.message}');
    }
  }

  // Fetch tasks by their status from Back4App
  Future<List<Task>> getTasksByStatus(String status) async {
    final query =
        QueryBuilder<Task>(Task())
          ..whereEqualTo('status', status)
          ..orderByDescending('createdAt');
    final response = await query.query();

    if (response.success && response.results != null) {
      return response.results!.map((task) => task as Task).toList();
    } else {
      return [];
    }
  }

  // Add a new task to Back4App
  Future<void> addTask(Task task) async {
    final response = await task.save();

    if (!response.success) {
      throw Exception('Failed to add task: ${response.error?.message}');
    }
  }

  // Update an existing task in Back4App
  Future<void> updateTask(Task updatedTask) async {
    final response = await updatedTask.save();

    if (!response.success) {
      throw Exception('Failed to update task: ${response.error?.message}');
    }
  }

  // Delete a task from Back4App by its objectId
  Future<void> deleteTask(String objectId) async {
    final query = QueryBuilder<Task>(Task())
      ..whereEqualTo('objectId', objectId);
    final response = await query.query();

    if (response.success && response.results != null) {
      Task taskToDelete = response.results!.first as Task;
      final deleteResponse = await taskToDelete.delete();

      if (!deleteResponse.success) {
        throw Exception(
          'Failed to delete task: ${deleteResponse.error?.message}',
        );
      }
    } else {
      throw Exception('Task not found to delete.');
    }
  }
}
