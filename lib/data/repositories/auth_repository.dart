import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

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
    String? phoneNumber,
    String? profileImageUrl,
  }) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user != null) {
        final now = DateTime.now();
        
        // Create user index entry (minimal data for quick lookups)
        final Map<String, dynamic> userIndexData = {
          'uid': user.uid,
          'email': email,
          'role': role,
          'firstName': firstName,
          'lastName': lastName,
          'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        };

        // Write to the main index collection
        await _firestore.collection('users-index').doc(user.uid).set(userIndexData);

        // Create role-specific user data
        print('Creating user with role: $role'); // Debug logging
        
        if (role == 'admin') {
          print('Creating admin user...'); // Debug logging
          final adminModel = AdminModel(
            uid: user.uid,
            email: email,
            role: role,
            firstName: firstName,
            lastName: lastName,
            phoneNumber: phoneNumber,
            profileImageUrl: profileImageUrl,
            createdAt: now,
            updatedAt: now,
          );
          
          await _firestore.collection('users-admin').doc(user.uid).set(adminModel.toJson());
          print('Admin user created successfully'); // Debug logging
        } else if (role == 'consumer') {
          print('Creating consumer user...'); // Debug logging
          final consumerModel = ConsumerModel(
            uid: user.uid,
            email: email,
            role: role,
            firstName: firstName,
            lastName: lastName,
            phoneNumber: phoneNumber,
            profileImageUrl: profileImageUrl,
            createdAt: now,
            updatedAt: now,
          );
          
          await _firestore.collection('users-consumer').doc(user.uid).set(consumerModel.toJson());
          print('Consumer user created successfully'); // Debug logging
        } else {
          print('Unknown role: $role'); // Debug logging for unexpected roles
        }
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

  // Get user data from the index
  Future<Map<String, dynamic>?> getUserIndexData(String uid) async {
    try {
      final doc = await _firestore.collection('users-index').doc(uid).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user index data: $e');
    }
  }

  // Get full user data based on role
  Future<UserModel?> getUserData(String uid, String role) async {
    try {
      String collectionName;
      switch (role) {
        case 'admin':
          collectionName = 'users-admin';
          break;
        case 'consumer':
          collectionName = 'users-consumer';
          break;
        default:
          throw ArgumentError('Unknown role: $role');
      }

      final doc = await _firestore.collection(collectionName).doc(uid).get();
      if (doc.exists) {
        return UserModel.fromJson(doc.data()!, uid);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user data: $e');
    }
  }

  // Update user data
  Future<void> updateUserData(String uid, String role, Map<String, dynamic> data) async {
    try {
      // final now = DateTime.now();
      data['updatedAt'] = FieldValue.serverTimestamp();

      // Update role-specific collection
      String collectionName;
      switch (role) {
        case 'admin':
          collectionName = 'users-admin';
          break;
        case 'consumer':
          collectionName = 'users-consumer';
          break;
        default:
          throw ArgumentError('Unknown role: $role');
      }

      await _firestore.collection(collectionName).doc(uid).update(data);

      // Update index with basic info if provided
      final indexData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      if (data['firstName'] != null) indexData['firstName'] = data['firstName'];
      if (data['lastName'] != null) indexData['lastName'] = data['lastName'];
      if (data['isActive'] != null) indexData['isActive'] = data['isActive'];

      await _firestore.collection('users-index').doc(uid).update(indexData);
    } catch (e) {
      throw Exception('Failed to update user data: $e');
    }
  }

  // Get all users from index (for admin purposes)
  Future<List<Map<String, dynamic>>> getAllUsersIndex() async {
    try {
      final querySnapshot = await _firestore.collection('users-index').get();
      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('Failed to get all users: $e');
    }
  }

  // Get users by role from index
  Future<List<Map<String, dynamic>>> getUsersByRole(String role) async {
    try {
      final querySnapshot = await _firestore
          .collection('users-index')
          .where('role', isEqualTo: role)
          .get();
      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('Failed to get users by role: $e');
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