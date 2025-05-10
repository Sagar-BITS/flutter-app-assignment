import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import '../models/task.dart';
import '../services/task_service.dart';

class TaskListPage extends StatefulWidget {
  const TaskListPage({super.key});

  @override
  State<TaskListPage> createState() => _TaskListPageState();
}

class _TaskListPageState extends State<TaskListPage> {
  final TaskService _taskService = TaskService();
  List<Task> _tasks = [];
  String _selectedFilter = 'All';

  final Color primaryColor = Colors.indigo;

  TextEditingController titleController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  DateTime? selectedDueDate;
  String selectedStatus = 'Pending';
  Task? editingTask;

  @override
  void initState() {
    super.initState();
    fetchTasks();
  }

  Future<void> fetchTasks() async {
    List<Task> tasks;
    if (_selectedFilter == 'All') {
      tasks = await _taskService.getTasks();
    } else {
      tasks = await _taskService.getTasksByStatus(_selectedFilter);
    }

    tasks = _sortTasks(tasks);

    setState(() {
      _tasks = tasks;
    });
  }

  List<Task> _sortTasks(List<Task> tasks) {
    tasks.sort(
      (a, b) =>
          (a.dueDate ?? DateTime.now()).compareTo(b.dueDate ?? DateTime.now()),
    );
    return tasks;
  }

  Future<void> addOrUpdateTask() async {
    final currentUser = await ParseUser.currentUser() as ParseUser?;
    if (titleController.text.isEmpty) return;

    if (editingTask == null) {
      final task =
          Task()
            ..title = titleController.text.trim()
            ..description = descriptionController.text.trim()
            ..status =
                selectedStatus // Set selected status
            ..owner = currentUser
            ..isDone = false
            ..dueDate = selectedDueDate ?? DateTime.now();
      await _taskService.addTask(task);
    } else {
      editingTask!
        ..title = titleController.text.trim()
        ..description = descriptionController.text.trim()
        ..status =
            selectedStatus // Update status for edited task
        ..dueDate = selectedDueDate ?? DateTime.now();
      await _taskService.updateTask(editingTask!);
    }

    clearForm();
    fetchTasks();
  }

  Future<void> updateTaskStatus(Task task, bool isDone) async {
    task.isDone = isDone;
    task.status = isDone ? 'Completed' : 'Pending';
    await _taskService.updateTask(task);
    fetchTasks();
  }

  Future<void> deleteTask(Task task) async {
    await _taskService.deleteTask(task.objectId!);
    fetchTasks();
  }

  void clearForm() {
    titleController.clear();
    descriptionController.clear();
    selectedDueDate = null;
    selectedStatus = 'Pending'; // Reset status when clearing form
    editingTask = null;
  }

  Future<void> pickDueDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );

    if (picked != null) {
      setState(() {
        selectedDueDate = picked;
      });
    }
  }

  Color _getChipColor(String? status) {
    switch (status) {
      case 'Completed':
        return Colors.green.shade100;
      case 'In Progress':
        return Colors.orange.shade100;
      default:
        return Colors.grey.shade300;
    }
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildDatePickerButton() {
    return Row(
      children: [
        const Text('Due Date:'),
        const SizedBox(width: 8),
        Text(
          selectedDueDate != null
              ? DateFormat.yMd().format(selectedDueDate!)
              : 'Not selected',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        IconButton(
          icon: const Icon(Icons.calendar_today, size: 20),
          onPressed: () async {
            await pickDueDate();
          },
        ),
      ],
    );
  }

  void _showAddEditTaskDialog({Task? task}) {
    if (task != null) {
      titleController.text = task.title ?? '';
      descriptionController.text = task.description ?? '';
      selectedDueDate = task.dueDate;
      selectedStatus = task.status ?? 'Pending';
      editingTask = task;
    } else {
      clearForm();
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            // <-- this setState only for dialog
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              backgroundColor: Colors.white,
              title: Text(
                editingTask == null ? 'Add Task' : 'Edit Task',
                style: TextStyle(color: primaryColor),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTextField(titleController, 'Title'),
                    const SizedBox(height: 10),
                    _buildTextField(
                      descriptionController,
                      'Description',
                      maxLines: 2,
                    ),
                    const SizedBox(height: 10),
                    _buildDatePickerButton(),
                    const SizedBox(height: 10),
                    InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: DropdownButton<String>(
                        value: selectedStatus,
                        isExpanded: true,
                        underline: Container(),
                        items:
                            ['Pending', 'In Progress', 'Completed']
                                .map(
                                  (status) => DropdownMenuItem<String>(
                                    value: status,
                                    child: Text(status),
                                  ),
                                )
                                .toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedStatus = value!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                  ),
                  onPressed: () async {
                    await addOrUpdateTask();
                    Navigator.of(context).pop();
                  },
                  child: Text(editingTask == null ? 'Add' : 'Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: const Text('Task List'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Text('Filter:'),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButton<String>(
                    value: _selectedFilter,
                    isExpanded: true,
                    borderRadius: BorderRadius.circular(12),
                    underline: Container(height: 0),
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
                ),
              ],
            ),
          ),
          Expanded(
            child:
                _tasks.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.inbox, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No tasks found',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: _tasks.length,
                      itemBuilder: (context, index) {
                        final task = _tasks[index];
                        return GestureDetector(
                          onTap: () => _showAddEditTaskDialog(task: task),
                          child: Card(
                            elevation: 5,
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          task.title ?? '',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        ),
                                      ),
                                      Checkbox(
                                        value: task.isDone,
                                        onChanged:
                                            (value) => updateTaskStatus(
                                              task,
                                              value ?? false,
                                            ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                        onPressed: () async {
                                          await deleteTask(task);
                                        },
                                      ),
                                    ],
                                  ),
                                  if ((task.description ?? '').isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      task.description ?? '',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Chip(
                                        label: Text(task.status ?? 'Pending'),
                                        backgroundColor: _getChipColor(
                                          task.status,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.calendar_today,
                                            size: 16,
                                            color: Colors.grey,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            task.dueDate != null
                                                ? DateFormat.yMMMd().format(
                                                  task.dueDate!,
                                                )
                                                : 'N/A',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditTaskDialog(),
        backgroundColor: primaryColor,
        label: const Text('Add Task'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
