import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class FcmTokenService {
  static Future<void> saveTokenToFirestore() async {
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'fcmToken': token,
      'tokenUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> deleteToken() async {
    await FirebaseMessaging.instance.deleteToken();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'fcmToken': FieldValue.delete(),
    }, SetOptions(merge: true));
  }
}
