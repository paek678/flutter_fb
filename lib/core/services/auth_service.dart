import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'firebase_service.dart'; // FirestoreService
import '../../features/auth/model/app_user.dart';

class AuthService {
  AuthService._();

  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// google-services.json 에 있는 web client (client_type: 3)
  static const String _webClientId =
      '800134555306-orq1jhqs4l8qim0vmo20tovkagovs5ld.apps.googleusercontent.com';

  // ---------------------------------------------------------------------------
  // 현재 로그인한 Firebase 유저
  // ---------------------------------------------------------------------------

  static User? get currentFirebaseUser => _auth.currentUser;

  // ---------------------------------------------------------------------------
  // 1) Google 로그인 + users 컬렉션 동기화
  //    - uid 기반 검색 → 없으면 AppUser 생성 → 있으면 lastLoginAt 갱신
  //    - 최종적으로 AppUser 리턴
  // ---------------------------------------------------------------------------

  static Future<AppUser> signInWithGoogle() async {
    // 모바일만 지원 (원하면 Platform 분기 빼도 됨)
    if (!Platform.isAndroid && !Platform.isIOS) {
      throw Exception('Google 로그인은 Android / iOS 에서만 지원됩니다.');
    }

    // 1) GoogleSignIn 초기화 (serverClientId 필수)
    await GoogleSignIn.instance.initialize(
      serverClientId: _webClientId,
    );

    // 2) Google 계정 선택 UI
    final GoogleSignInAccount? googleUser =
        await GoogleSignIn.instance.authenticate();

    if (googleUser == null) {
      // 사용자가 취소
      throw Exception('사용자가 Google 로그인을 취소했습니다.');
    }

    // 3) 토큰 -> Firebase Credential
    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );

    // 4) Firebase Auth 로그인
    final UserCredential userCredential =
        await _auth.signInWithCredential(credential);

    final User? user = userCredential.user;
    if (user == null) {
      throw Exception('Firebase 로그인 실패: user == null');
    }

    final now = DateTime.now();
    final uid = user.uid;

    // 5) Firestore users 컬렉션 동기화
    final existing = await FirestoreService.getUserByUid(uid);

    if (existing == null) {
      final newUser = AppUser(
        uid: uid,
        email: user.email,
        displayName: user.displayName ?? 'User',
        provider: 'google',
        role: 'user',
        createdAt: now,
        lastLoginAt: now,
        lastActionAt: now,
      );
      await FirestoreService.createUser(newUser);
      return newUser;
    } else {
      final updated = existing.copyWith(lastLoginAt: now);
      await FirestoreService.updateUser(updated);
      return updated;
    }
  }

  // ---------------------------------------------------------------------------
  // 2) 게스트 로그인 (익명 Auth + users 컬렉션에 guest 유저 생성)
  //    - 이미 익명 계정 있으면 그대로 사용
  //    - 필요 없으면 그냥 Navigator 로 팝업만 띄우는 용도로 안 써도 됨
  // ---------------------------------------------------------------------------

  static Future<AppUser> signInAsGuest() async {
    User? user = _auth.currentUser;

    // 이미 익명 계정이면 그거 재사용
    if (user == null || !user.isAnonymous) {
      final cred = await _auth.signInAnonymously();
      user = cred.user;
    }

    if (user == null) {
      throw Exception('익명 로그인 실패: user == null');
    }

    final now = DateTime.now();
    final uid = user.uid;

    final existing = await FirestoreService.getUserByUid(uid);

    if (existing == null) {
      final guest = AppUser(
        uid: uid,
        email: null,
        displayName: 'Guest',
        provider: 'anonymous',
        role: 'guest',
        createdAt: now,
        lastLoginAt: now,
        lastActionAt: now,
      );
      await FirestoreService.createUser(guest);
      return guest;
    } else {
      final updated = existing.copyWith(lastLoginAt: now);
      await FirestoreService.updateUser(updated);
      return updated;
    }
  }

  // ---------------------------------------------------------------------------
  // 3) 로그아웃
  // ---------------------------------------------------------------------------

  static Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
     GoogleSignIn.instance.signOut(), // ✅ 싱글톤 인스턴스 사용
    ]);
  }
}
