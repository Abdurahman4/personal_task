import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:personal_task/screens/home_screen.dart';
import 'package:personal_task/screens/login_screen.dart';
import 'package:personal_task/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  await NotificationService().initNotifications();

  bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
  if (!isAllowed) {
    AwesomeNotifications().requestPermissionToSendNotifications();
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Personal Task Management',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.yellow,
        useMaterial3: true,
      ),
      home: const AuthCheck(),
    );
  }
}

class AuthCheck extends StatelessWidget {
  const AuthCheck({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          return const HomeScreen();
        }

        return const LoginScreen();
      },
    );
  }
}
