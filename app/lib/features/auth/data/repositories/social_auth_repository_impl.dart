import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:imjang_app/core/error/exceptions.dart';
import 'package:imjang_app/features/auth/domain/entities/user_entity.dart';

class SocialAuthRepositoryImpl {
  final FirebaseAuth firebaseAuth;
  final FirebaseFirestore firestore;
  final GoogleSignIn googleSignIn;

  SocialAuthRepositoryImpl({
    required this.firebaseAuth,
    required this.firestore,
    required this.googleSignIn,
  });

  /// Google Sign-In flow
  Future<UserEntity> signInWithGoogle() async {
    try {
      final googleAccount = await googleSignIn.signIn();
      if (googleAccount == null) {
        throw SocialAuthCancelledException();
      }

      final googleAuth = await googleAccount.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );

      final userCredential =
          await firebaseAuth.signInWithCredential(credential);
      final user = userCredential.user!;

      await _createUserDocumentIfNeeded(user, 'google');

      return UserEntity(
        uid: user.uid,
        email: user.email ?? '',
        displayName: user.displayName ?? '',
        photoUrl: user.photoURL,
        authProvider: 'google',
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
      );
    } on SocialAuthCancelledException {
      rethrow;
    } on FirebaseAuthException catch (_) {
      throw AuthAppException(
        code: 'social-auth-error',
        message: '소셜 로그인 중 오류가 발생했습니다',
      );
    }
  }

  /// Apple Sign-In — production flow using sign_in_with_apple package
  Future<UserEntity> signInWithApple() async {
    try {
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      return signInWithAppleForTest(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
      );
    } on SignInWithAppleAuthorizationException {
      throw SocialAuthCancelledException();
    }
  }

  String _generateNonce([int length = 32]) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Apple Sign-In test helper — accepts pre-fetched tokens
  Future<UserEntity> signInWithAppleForTest({
    required String? idToken,
    required String? rawNonce,
  }) async {
    if (idToken == null || rawNonce == null) {
      throw SocialAuthCancelledException();
    }

    final credential = OAuthProvider('apple.com').credential(
      idToken: idToken,
      rawNonce: rawNonce,
    );

    final userCredential =
        await firebaseAuth.signInWithCredential(credential);
    final user = userCredential.user!;

    await _createUserDocumentIfNeeded(user, 'apple');

    return UserEntity(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName ?? '',
      photoUrl: user.photoURL,
      authProvider: 'apple',
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
    );
  }

  /// Sign out from both Google and Firebase
  Future<void> signOut() async {
    await googleSignIn.signOut();
    await firebaseAuth.signOut();
  }

  /// Create Firestore user document if it doesn't exist yet
  Future<void> _createUserDocumentIfNeeded(
    User user,
    String authProvider,
  ) async {
    final docRef = firestore.collection('users').doc(user.uid);
    final docSnapshot = await docRef.get();

    if (!docSnapshot.exists) {
      await docRef.set({
        'uid': user.uid,
        'email': user.email ?? '',
        'displayName': user.displayName ?? '',
        'photoUrl': user.photoURL,
        'authProvider': authProvider,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
      });
    }
  }
}
