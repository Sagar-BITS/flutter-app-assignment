import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'task_list_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _isSignUpMode = false; // Toggle between login and sign-up

  // Sign up function to create a new user
  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final user = ParseUser(
      _usernameController.text,
      _passwordController.text,
      _emailController.text,
    );

    try {
      final response = await user.signUp();

      if (response.success) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('User created successfully!')));
        setState(() {
          _isSignUpMode =
              false; // Switch to login mode after successful sign-up
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${response.error?.message}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Log in function to log an existing user in
  Future<void> _logIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final user = ParseUser(
      _usernameController.text,
      _passwordController.text,
      null,
    );

    try {
      final response = await user.login();

      if (response.success) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Login successful!')));
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => TaskListPage(),
          ), // Navigate to task list page
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${response.error?.message}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isSignUpMode ? 'Sign Up' : 'Log In')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Username Field
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(labelText: 'Username'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a username';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Email Field (Only for Sign-Up)
              if (_isSignUpMode)
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an email address';
                    }
                    if (!RegExp(
                      r'^[a-zA-Z0-9]+@[a-zA-Z0-9]+\.[a-zA-Z]',
                    ).hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
              SizedBox(height: 16),

              // Password Field
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a password';
                  }
                  if (value.length < 6) {
                    return 'Password should be at least 6 characters long';
                  }
                  return null;
                },
              ),
              SizedBox(height: 32),

              // Action Button (Sign Up or Log In)
              _isLoading
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                    onPressed: _isSignUpMode ? _signUp : _logIn,
                    child: Text(_isSignUpMode ? 'Sign Up' : 'Log In'),
                  ),

              // Toggle between Sign-Up and Login
              TextButton(
                onPressed: () {
                  setState(() {
                    _isSignUpMode = !_isSignUpMode; // Toggle the mode
                  });
                },
                child: Text(
                  _isSignUpMode
                      ? 'Already have an account? Log in'
                      : 'Don\'t have an account? Sign up',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
