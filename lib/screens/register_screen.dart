import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:personal_task/screens/login_screen.dart';
//import 'package:personal_task/services/firestore_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool isPasswordStrong(String password) {
    // تحقق من 8 حروف على الأقل + حرف كبير + حرف صغير + رقم
    final hasUppercase = password.contains(RegExp(r'[A-Z]'));
    final hasLowercase = password.contains(RegExp(r'[a-z]'));
    final hasNumber = password.contains(RegExp(r'[0-9]'));

    return password.length >= 8 && hasUppercase && hasLowercase && hasNumber;
  }

  Future<void> _register() async {
    if (_usernameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
          'Please enter a username',
          style: TextStyle(fontSize: 15, color: Colors.red),
        )),
      );
      return;
    }

    String email = _emailController.text.trim();
    if (!email.endsWith('@gmail.com') || email.split('@')[0].isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a valid Gmail address')),
      );
      return;
    }

    if (!isPasswordStrong(_passwordController.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'The password must contain at least 8 characters, including an uppercase'
                'and lowercase letter and a number.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });
    try {
      UserCredential account = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      String uid = account.user!.uid;
      String username = _usernameController.text.trim();
      String email = _emailController.text.trim();

      // **Save user data in Firestore**
      await _firestore.collection('users').doc(uid).set({
        'username': username,
        'email': email,
        'createdAt': Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Account created successfully!')),
      );
      // **Log out after registration**
      await _auth.signOut();

      // **Go to login screen**
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => LoginScreen()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create account: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Create a new account')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: 'Username'),
            ),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            SizedBox(height: 16),
            _isLoading
                ? Center(
                    child: CircularProgressIndicator(),
                  )
                : InkWell(
                    onTap: _register,
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.deepPurple,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          ' Create account',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
