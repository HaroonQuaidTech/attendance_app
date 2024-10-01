import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseAuthServices {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<UserCredential> signUpwithEmailandPassword(
      String email, password, name) async {
    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      // saving firestore
      //  String? token =  await FirebaseMessaging.instance.getToken();

      try {
        await _firestore.collection("Users").doc(userCredential.user!.uid).set({
          'uid': userCredential.user!.uid,
          'email': email,
          'name': name,
        });
      } catch (e) {
        log(e.toString());
      }
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.code);
    }
  }

  Future<UserCredential> signInwithEmailandPassword(
      String email, password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      //     String? token =  await FirebaseMessaging.instance.getToken();
      //  await FirebaseFirestore.instance
      //   .collection('Users')
      //   .doc(userCredential.user!.uid)
      //   .update({'token': token});
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.code);
    }
  }
}
