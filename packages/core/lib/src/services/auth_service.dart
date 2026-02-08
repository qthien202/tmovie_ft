import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late final GoogleSignIn _googleSignIn;

  AuthService() {
    _googleSignIn = GoogleSignIn(
      clientId: Platform.isIOS
          ? '689830026078-ev3ikjj7l1io2n8tknuqgpj44dal126p.apps.googleusercontent.com'
          : null,
      serverClientId:
          '689830026078-kh1qnbfu1ecbfcmr1ge51kvgo8oc8v8l.apps.googleusercontent.com',
    );
  }

  Stream<User?> get authStateChanges => _auth.authStateChanges().map((user) {
        print('Auth state changed: ${user?.email ?? "null"}');
        return user;
      });
  User? get currentUser => _auth.currentUser;

  Future<User?> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      return userCredential.user;
    } catch (e) {
      print('Google Sign-In error: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
