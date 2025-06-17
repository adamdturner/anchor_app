import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  AuthRepository({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;


  // function to create a new user and log them in at the same time
  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String role,
    required String firstName,
    required String lastName,
  }) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user != null) {
        final Map<String, dynamic> userData = {
          'email': email,
          'role': role,
          'firstName': firstName,
          'lastName': lastName,
          'createdAt': FieldValue.serverTimestamp(),
        };

        await _firestore.collection('user-accounts').doc(user.uid).set(userData);
      }

      return userCredential;
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw Exception('Failed to create user account: $e');
    }
  }



  // function to log in an existing user if they give the correct username/password combo
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException {
      rethrow; // Propagate FirebaseAuthException to the caller
    } catch (e) {
      throw Exception('Failed to sign in: $e');
    }
  }


  Future<void> resetPassword(String email) async {
    await _firebaseAuth.sendPasswordResetEmail(email: email);
  }



  // function to log out a user that was previously logged in
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }


  User? getCurrentUser() {
    return _firebaseAuth.currentUser;
  }

}