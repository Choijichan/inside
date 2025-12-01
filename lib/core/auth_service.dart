// lib/core/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  AuthService._();
  static final instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// 현재 유저 (null이면 로그인 안 된 상태)
  User? get currentUser => _auth.currentUser;

  /// 유저 변경 스트림 (로그인/로그아웃 시 감지)
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// 구글 로그인
  Future<User?> signInWithGoogle() async {
    // 1. 구글 계정 선택
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      // 사용자가 로그인 취소
      return null;
    }

    // 2. 인증 정보 가져오기
    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    // 3. Firebase Auth credential 만들기
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // 4. Firebase 로그인
    final UserCredential userCredential =
        await _auth.signInWithCredential(credential);

    return userCredential.user;
  }

  /// 로그아웃
  Future<void> signOut() async {
    // 구글 계정 로그아웃
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    // Firebase 로그아웃
    await _auth.signOut();
  }
}
