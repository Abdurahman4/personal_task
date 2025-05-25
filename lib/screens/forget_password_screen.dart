import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForgetPasswordScreen extends StatefulWidget {
  const ForgetPasswordScreen({super.key});

  @override
  _ForgetPasswordScreenState createState() => _ForgetPasswordScreenState();
}

class _ForgetPasswordScreenState extends State<ForgetPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _resetPassword() async {
    try {
      await _auth.sendPasswordResetEmail(email: _emailController.text.trim());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('A password reset link has been sent to your email.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error occurred: Please check your email.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Reset password')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Enter your email and we will send you a link to reset your password.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'emaile',
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _resetPassword,
              child: Text('Reset link message'),
            ),
          ],
        ),
      ),
    );
  }
}
