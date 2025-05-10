import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import '../models/task.dart';

class TaskService {
  // Fetch tasks only for the logged-in user
  Future<List<Task>> getTasks() async {
    final user = await ParseUser.currentUser() as ParseUser?;
    if (user == null) throw Exception('No logged-in user found.');

    final query =
        QueryBuilder<Task>(Task())
          ..whereEqualTo('owner', user)
          ..orderByDescending('dueDate');

    final response = await query.query();

    if (response.success && response.results != null) {
      return response.results!.map((task) => task as Task).toList();
    } else {
      throw Exception('Failed to fetch tasks: ${response.error?.message}');
    }
  }

  // Fetch tasks for the logged-in user by status
  Future<List<Task>> getTasksByStatus(String status) async {
    final user = await ParseUser.currentUser() as ParseUser?;
    if (user == null) throw Exception('No logged-in user found.');

    final query =
        QueryBuilder<Task>(Task())
          ..whereEqualTo('owner', user)
          ..whereEqualTo('status', status)
          ..orderByDescending('dueDate');

    final response = await query.query();

    if (response.success && response.results != null) {
      return response.results!.map((task) => task as Task).toList();
    } else {
      return [];
    }
  }

  // Add a new task linked to the current user
  Future<void> addTask(Task task) async {
    final user = await ParseUser.currentUser() as ParseUser?;
    if (user == null) throw Exception('No logged-in user found.');

    task.set('owner', user); // Link task to user
    final response = await task.save();

    if (!response.success) {
      throw Exception('Failed to add task: ${response.error?.message}');
    }
  }

  // Update an existing task
  Future<void> updateTask(Task updatedTask) async {
    final response = await updatedTask.save();

    if (!response.success) {
      throw Exception('Failed to update task: ${response.error?.message}');
    }
  }

  // Delete a task by its objectId
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
