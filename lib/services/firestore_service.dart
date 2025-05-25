/*
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  //this function bring userdata to use it in another place
  Future<Map<String, dynamic>> getUserData() async {
    try {
      User? user = _auth.currentUser;

      // **الانتظار حتى يتم تحديث currentUser**
      if (user == null) {
        await Future.delayed(Duration(seconds: 2));
        user = _auth.currentUser;
        if (user == null) return {};
      }

      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user.uid).get();

      if (userDoc.exists) {
        print("✅ بيانات المستخدم: ${userDoc.data()}");
        return userDoc.data() as Map<String, dynamic>;
      }
    } catch (e) {
      print("⚠️ خطأ في جلب بيانات المستخدم: $e");
    }
    return {};
  }
}
*/
