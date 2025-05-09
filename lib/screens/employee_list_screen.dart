import 'package:flutter/material.dart';
import '../models/employee.dart';
import '../services/employee_service.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import 'employee_form_screen.dart';
import 'login_screen.dart';
import 'notification_history_screen.dart';
import 'package:timeago/timeago.dart' as timeago;

class EmployeeListScreen extends StatefulWidget {
  const EmployeeListScreen({super.key});

  @override
  State<EmployeeListScreen> createState() => _EmployeeListScreenState();
}

class _EmployeeListScreenState extends State<EmployeeListScreen> {
  final _employeeService = EmployeeService();
  final _authService = AuthService();
  List<Employee> _employees = [];
  bool _isLoading = true;
  bool _isDeleting = false; // New state for delete operation
  int? _deletingIndex; // Track which item is being deleted

  void _showNotificationsPopup(BuildContext context) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay = Overlay.of(context)
        .context
        .findRenderObject() as RenderBox;
    final buttonPosition = button.localToGlobal(Offset.zero, ancestor: overlay);
    
    final position = RelativeRect.fromRect(
      Rect.fromPoints(
        buttonPosition.translate(0, button.size.height),
        buttonPosition.translate(button.size.width, button.size.height),
      ),
      Offset.zero & overlay.size,
    );

    showMenu(
      context: context,
      position: position,
      elevation: 8,
      constraints: const BoxConstraints(
        maxWidth: 300,
        maxHeight: 400,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      items: [
        PopupMenuItem(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Notifications',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ValueListenableBuilder<int>(
                      valueListenable: NotificationService.notificationCount,
                      builder: (context, count, _) {
                        if (count == 0) return const SizedBox();
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            count.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const Divider(),
            ],
          ),
        ),
        ...NotificationService.getNotifications().map(
          (notification) => PopupMenuItem(
            enabled: false,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                notification.isSuccess
                    ? Icons.check_circle
                    : Icons.error,
                color: notification.isSuccess
                    ? Colors.green
                    : Colors.red,
              ),
              title: Text(
                notification.message,
                style: const TextStyle(fontSize: 14),
              ),
              subtitle: Text(
                timeago.format(notification.timestamp),
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ),
        if (NotificationService.getNotifications().isEmpty)
          const PopupMenuItem(
            enabled: false,
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  'No notifications in the last 24 hours',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    _checkAuthAndLoadEmployees();
  }

  Future<void> _checkAuthAndLoadEmployees() async {
    try {
      final isLoggedIn = await _authService.isLoggedIn();
      if (!isLoggedIn && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
        return;
      }
      await _loadEmployees();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadEmployees() async {
    try {
      print('📱 EmployeeListScreen: Starting employee load...'); // Added entry log
      setState(() => _isLoading = true);
      
      final employees = await _employeeService.getEmployees();
      
      if (mounted) {
        setState(() {
          _employees = employees;
          _isLoading = false;
        });
        print('✅ EmployeeListScreen: Successfully loaded ${employees.length} employees');
      }
    } catch (e, stackTrace) {
      print('========================== SCREEN ERROR LOG ==========================');
      print('🔴 Error in EmployeeListScreen._loadEmployees:');
      print('Error: $e');
      print('Stack Trace:');
      print(stackTrace);
      print('=================================================================');

      if (mounted) {
        if (e.toString().contains('Invalid session token')) {
          print('🔄 Handling session expiration...');
          await _authService.logout();
          const message = 'Session expired. Please login again.';
          print('🔴 Showing error to user: $message');
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Session expired. Please login again.'),
              backgroundColor: Colors.red,
            ),
          );
        } else {
          final errorMessage = 'Error loading employees: ${e.toString()}';
          print('🔴 Showing error to user: $errorMessage');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: _loadEmployees,
              ),
            ),
          );
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<void> _showEmployeeForm({Employee? employee}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EmployeeFormScreen(employee: employee),
      ),
    );

    if (result == true) {
      await _loadEmployees();
      if (mounted) {
        NotificationService.showNotification(
          context,
          message: employee == null 
              ? 'Employee added successfully'
              : 'Employee updated successfully',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee Management'),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationHistoryScreen(),
                  ),
                ),
              ),
              Positioned(
                right: 12,
                top: 8,
                child: ValueListenableBuilder<int>(
                  valueListenable: NotificationService.notificationCount,
                  builder: (context, count, child) {
                    if (count == 0) return const SizedBox();
                    return GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationHistoryScreen(),
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 14,
                          minHeight: 14,
                        ),
                        child: Text(
                          count.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              try {
                final success = await AuthService().logout();
                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('User logged out successfully'),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                      duration: Duration(seconds: 2),
                    ),
                  );
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Logout failed: ${e.toString()}'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading employees...'),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Header Row
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(10),
                        topRight: Radius.circular(10),
                      ),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(
                              'Name & Email',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Position',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 100,
                            child: Text(
                              'Actions',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Data Rows
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(10),
                          bottomRight: Radius.circular(10),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            spreadRadius: 1,
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: ListView.builder(
                        itemCount: _employees.length,
                        itemBuilder: (context, index) {
                          final employee = _employees[index];
                          final isDeleting = _isDeleting && _deletingIndex == index;
                          
                          return Container(
                            decoration: BoxDecoration(
                              color: index.isEven
                                  ? Colors.grey.shade50
                                  : Colors.white,
                              border: Border(
                                bottom: BorderSide(
                                  color: Colors.grey.shade200,
                                  width: 1,
                                ),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          employee.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          employee.email,
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      employee.position,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 100,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.edit,
                                            color: Colors.blue,
                                            size: 20,
                                          ),
                                          onPressed: isDeleting
                                              ? null
                                              : () => _showEmployeeForm(
                                                    employee: employee,
                                                  ),
                                          tooltip: 'Edit Employee',
                                          constraints: const BoxConstraints(
                                            minWidth: 40,
                                            minHeight: 40,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        isDeleting
                                            ? const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                ),
                                              )
                                            : IconButton(
                                                icon: const Icon(
                                                  Icons.delete,
                                                  color: Colors.red,
                                                  size: 20,
                                                ),
                                                onPressed: () => _deleteEmployee(
                                                  employee,
                                                  index,
                                                ),
                                                tooltip: 'Delete Employee',
                                                constraints: const BoxConstraints(
                                                  minWidth: 40,
                                                  minHeight: 40,
                                                ),
                                              ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading ? null : () => _showEmployeeForm(),
        icon: const Icon(Icons.add),
        label: const Text('Add Employee'),
      ),
    );
  }

  Future<void> _deleteEmployee(Employee employee, int index) async {
    setState(() {
      _isDeleting = true;
      _deletingIndex = index;
    });

    try {
      await _employeeService.deleteEmployee(employee);
      _employees.removeAt(index);
      
      if (mounted) {
        NotificationService.showNotification(
          context,
          message: 'Employee deleted successfully',
        );
      }
    } catch (e) {
      if (mounted) {
        NotificationService.showNotification(
          context,
          message: 'Failed to delete employee: ${e.toString()}',
          isSuccess: false,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
          _deletingIndex = -1;
        });
      }
    }
  }
}


