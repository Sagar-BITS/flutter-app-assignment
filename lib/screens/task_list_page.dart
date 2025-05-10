import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import '../models/task.dart';

class TaskListPage extends StatefulWidget {
  const TaskListPage({super.key});

  @override
  State<TaskListPage> createState() => _TaskListPageState();
}

class _TaskListPageState extends State<TaskListPage> {
  String _selectedFilter = 'All';
  bool _sortByDueDateAsc = true;

  List<Task> tasks = [];
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  DateTime? selectedDueDate;

  final List<String> statusOptions = ['Pending', 'In Progress', 'Completed'];

  @override
  void initState() {
    super.initState();
    fetchTasks();
  }

  Future<void> fetchTasks() async {
    final currentUser = await ParseUser.currentUser() as ParseUser?;
    final query = QueryBuilder<Task>(Task())
      ..whereEqualTo('owner', currentUser);

    if (_selectedFilter != 'All') {
      query.whereEqualTo('status', _selectedFilter);
    }

    if (_sortByDueDateAsc) {
      query.orderByAscending('dueDate');
    } else {
      query.orderByDescending('dueDate');
    }

    final response = await query.query();
    if (response.success && response.results != null) {
      setState(() {
        tasks = response.results!.cast<Task>();
      });
    } else {
      print('❌ Error loading tasks: ${response.error?.message}');
    }
  }

  Future<void> pickDueDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDueDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        selectedDueDate = picked;
      });
    }
  }

  Future<void> addTask() async {
    final currentUser = await ParseUser.currentUser() as ParseUser?;

    final task =
        Task()
          ..title = titleController.text.trim()
          ..description = descriptionController.text.trim()
          ..status = 'Pending'
          ..owner = currentUser
          ..isDone = false
          ..dueDate = selectedDueDate ?? DateTime.now();

    final response = await task.save();
    if (response.success) {
      titleController.clear();
      descriptionController.clear();
      selectedDueDate = null;
      fetchTasks();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Task added successfully')),
      );
    } else {
      print('❌ Failed to add task: ${response.error?.message}');
    }
  }

  Future<void> updateTaskStatus(Task task, bool newStatus) async {
    task.isDone = newStatus;
    task.status = newStatus ? 'Completed' : 'Pending';

    final response = await task.save();
    if (response.success) {
      await fetchTasks(); // ✅ Reload all tasks to reflect the changes
    } else {
      print('❌ Failed to update task status: ${response.error?.message}');
    }
  }

  void showEditTaskDialog(Task task) {
    final editTitleController = TextEditingController(text: task.title);
    final editDescriptionController = TextEditingController(
      text: task.description,
    );
    DateTime? editDueDate = task.dueDate;
    String selectedStatus =
        statusOptions.contains(task.status)
            ? task.status!
            : statusOptions.first;
    bool isCompleted = task.isDone;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder:
              (context, setState) => AlertDialog(
                title: const Text('Edit Task'),
                content: SingleChildScrollView(
                  child: Column(
                    children: [
                      TextField(
                        controller: editTitleController,
                        decoration: const InputDecoration(labelText: 'Title'),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: editDescriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Text('Status:'),
                          const SizedBox(width: 10),
                          DropdownButton<String>(
                            value: selectedStatus,
                            items:
                                statusOptions.map((status) {
                                  return DropdownMenuItem<String>(
                                    value: status,
                                    child: Text(status),
                                  );
                                }).toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedStatus = value!;
                                isCompleted = selectedStatus == 'Completed';
                              });
                            },
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Text('Completed'),
                          Checkbox(
                            value: isCompleted,
                            onChanged: (value) {
                              setState(() {
                                isCompleted = value ?? false;
                                selectedStatus =
                                    isCompleted ? 'Completed' : 'Pending';
                              });
                            },
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Text('Due Date: '),
                          Text(
                            editDueDate != null
                                ? DateFormat.yMd().format(editDueDate!)
                                : '',
                          ),
                          IconButton(
                            icon: const Icon(Icons.calendar_today),
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: editDueDate ?? DateTime.now(),
                                firstDate: DateTime.now(),
                                lastDate: DateTime(2100),
                              );
                              if (picked != null) {
                                setState(() {
                                  editDueDate = picked;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      task
                        ..title = editTitleController.text
                        ..description = editDescriptionController.text
                        ..dueDate = editDueDate
                        ..status = selectedStatus
                        ..isDone = isCompleted;

                      final response = await task.save();
                      Navigator.of(context).pop();

                      if (response.success) {
                        await fetchTasks(); // ✅ Reload tasks from database with updated data
                      } else {
                        print('❌ Failed to update: ${response.error?.message}');
                      }
                    },
                    child: const Text('Save'),
                  ),
                ],
              ),
        );
      },
    );
  }

  Future<void> deleteTask(Task task) async {
    final response = await task.delete();
    if (response.success) {
      fetchTasks();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🗑️ Task deleted successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Task Manager')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('Due Date: '),
                    Text(
                      selectedDueDate != null
                          ? DateFormat.yMd().format(selectedDueDate!)
                          : '',
                    ),
                    IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: pickDueDate,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: addTask,
                  child: const Text('Add Task'),
                ),
              ],
            ),
          ),
          const Divider(),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                DropdownButton<String>(
                  value: _selectedFilter,
                  items:
                      ['All', 'Pending', 'In Progress', 'Completed']
                          .map(
                            (status) => DropdownMenuItem(
                              value: status,
                              child: Text(status),
                            ),
                          )
                          .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedFilter = value!;
                      fetchTasks();
                    });
                  },
                ),
                IconButton(
                  icon: Icon(
                    _sortByDueDateAsc
                        ? Icons.arrow_downward
                        : Icons.arrow_upward,
                  ),
                  tooltip: 'Sort by Due Date',
                  onPressed: () {
                    setState(() {
                      _sortByDueDateAsc = !_sortByDueDateAsc;
                      fetchTasks();
                    });
                  },
                ),
              ],
            ),
          ),

          Expanded(
            child:
                tasks.isEmpty
                    ? const Center(child: Text('No tasks found.'))
                    : ListView.builder(
                      itemCount: tasks.length,
                      itemBuilder: (context, index) {
                        final task = tasks[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          child: ListTile(
                            title: Text(
                              task.title ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(task.description ?? ''),
                                Text('Status: ${task.status ?? 'Pending'}'),
                                Text(
                                  'Due: ${task.dueDate != null ? DateFormat.yMd().format(task.dueDate!) : 'N/A'}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            leading: Checkbox(
                              value: task.isDone,
                              onChanged:
                                  (value) =>
                                      updateTaskStatus(task, value ?? false),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => deleteTask(task),
                            ),
                            onTap: () => showEditTaskDialog(task),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
