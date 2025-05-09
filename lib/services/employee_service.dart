import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import '../models/employee.dart';
import '../services/auth_service.dart';

class EmployeeService {
  final _authService = AuthService();

  void _logError(String operation, dynamic error, StackTrace? stackTrace) {
    debugPrint('========================== SERVICE ERROR LOG ==========================');
    debugPrint('🔴 Error in EmployeeService.$operation:');
    debugPrint('Error: $error');
    if (stackTrace != null) {
      debugPrint('Stack Trace:');
      debugPrint(stackTrace.toString());
    }
    debugPrint('===================================================================');
  }

  Future<List<Employee>> getEmployees() async {
    try {
      final QueryBuilder<Employee> query = QueryBuilder(Employee());
      query.orderByDescending('createdAt');
      
      final apiResponse = await query.query();
      if (!apiResponse.success || apiResponse.results == null) {
        throw Exception('Failed to fetch employees: ${apiResponse.error?.message}');
      }

      return apiResponse.results?.map((result) => result as Employee).toList() ?? [];
    } catch (e, stackTrace) {
      _logError('getEmployees', e, stackTrace);
      throw Exception('Failed to fetch employees: $e');
    }
  }

  Future<bool> createEmployee(Employee employee) async {
    try {
      debugPrint('📤 Creating new employee: ${employee.name}');
      
      final currentUser = await ParseUser.currentUser();
      if (currentUser == null) {
        const error = 'User not authenticated';
        _logError('createEmployee', error, null);
        throw Exception(error);
      }

      // Validate session token
      final sessionToken = currentUser.sessionToken;
      if (sessionToken == null) {
        const error = 'Invalid session token';
        _logError('createEmployee - token validation', error, null);
        await _authService.logout();
        throw Exception('Invalid session token');
      }

      // Set ACL
      final acl = ParseACL(owner: currentUser);
      acl.setPublicReadAccess(allowed: true);
      acl.setPublicWriteAccess(allowed: false);
      employee.setACL(acl);

      final response = await employee.save();
      if (!response.success) {
        final error = 'Save failed: ${response.error?.message}';
        _logError('createEmployee - save', error, null);
        throw Exception('Failed to create employee: ${response.error?.message}');
      }

      debugPrint('✅ Successfully created employee: ${employee.name}');
      return response.success;
      
    } catch (e, stackTrace) {
      _logError('createEmployee', e, stackTrace);
      if (e.toString().contains('Invalid session token')) {
        await _authService.logout();
      }
      throw Exception('Failed to create employee: $e');
    }
  }

  Future<bool> updateEmployee(Employee employee) async {
    try {
      debugPrint('🔄 Updating employee: ${employee.name}');
      
      final currentUser = await ParseUser.currentUser();
      if (currentUser == null) {
        const error = 'User not authenticated';
        _logError('updateEmployee', error, null);
        throw Exception(error);
      }

      // Validate session token
      final sessionToken = currentUser.sessionToken;
      if (sessionToken == null) {
        const error = 'Invalid session token';
        _logError('updateEmployee - token validation', error, null);
        await _authService.logout();
        throw Exception('Invalid session token');
      }

      final response = await employee.save();
      if (!response.success) {
        final error = 'Update failed: ${response.error?.message}';
        _logError('updateEmployee - save', error, null);
        throw Exception('Failed to update employee: ${response.error?.message}');
      }

      debugPrint('✅ Successfully updated employee: ${employee.name}');
      return response.success;
      
    } catch (e, stackTrace) {
      _logError('updateEmployee', e, stackTrace);
      if (e.toString().contains('Invalid session token')) {
        await _authService.logout();
      }
      throw Exception('Failed to update employee: $e');
    }
  }

  Future<bool> deleteEmployee(Employee employee) async {
    try {
      final currentUser = await ParseUser.currentUser();
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final response = await employee.delete();
      if (!response.success) {
        throw Exception('Failed to delete employee: ${response.error?.message}');
      }

      return response.success;
    } catch (e, stackTrace) {
      _logError('deleteEmployee', e, stackTrace);
      if (e.toString().contains('Invalid session token')) {
        await _authService.logout();
      }
      throw Exception('Failed to delete employee: $e');
    }
  }
}
















