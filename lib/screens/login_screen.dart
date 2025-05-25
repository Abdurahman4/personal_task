import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:personal_task/screens/home_screen.dart';
import 'package:personal_task/screens/register_screen.dart';
import 'package:personal_task/screens/forget_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() => _isLoading = true);

    try {
      await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('email or password is incorrect, please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Log in')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'email'),
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            _isLoading
                ? const CircularProgressIndicator()
                : InkWell(
                    onTap: _login,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.deepPurple,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text(
                          'Log in',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    ),
                  ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ForgetPasswordScreen()),
                );
              },
              child: const Text(
                'Forget Password?',
                style: TextStyle(color: Colors.blue, fontSize: 14),
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const RegisterScreen()),
                );
              },
              child: const Text(
                "Don't have an account? Create a new account",
                style: TextStyle(color: Colors.blue),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
