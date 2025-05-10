import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import '../models/user.dart';

class AuthService {
  Future<ParseResponse> signUp(
    String username,
    String email,
    String password,
  ) async {
    final user = User(
      username: username,
      password: password.trim(),
      emailAddress: email,
    );
    print('Hello, $user');
    return await user.signUp();
  }

  Future<ParseResponse> login(String email, String password) async {
    try {
      final user = ParseUser(email, password, email);
      final response = await user.login();

      if (!response.success) {
        print(
          'Login failed: ${response.error?.message} (Code: ${response.error?.code})',
        );
      }

      return response;
    } catch (e) {
      print('Login exception: $e');
      final response = ParseResponse();
      response.error = ParseError(
        code: -1,
        message: 'Login failed: ${e.toString()}',
      );
      return response;
    }
  }
}
