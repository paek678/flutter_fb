import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_fb/core/services/firebase_service.dart';
import 'package:flutter_fb/features/auth/model/app_user.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isSigningIn = false;
  static bool _googleInitialized = false;

  static const String _webClientId =
      '800134555306-orq1jhqs4l8qim0vmo20tovkagovs5ld.apps.googleusercontent.com';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _continueAsGuest() {
    Navigator.pushNamed(context, '/guest_login');
  }

  Future<void> _onGoogleLogin() async {
    if (_isSigningIn) return;

    if (!Platform.isAndroid && !Platform.isIOS) {
      _showSnack('Google 로그인은 Android/iOS에서만 지원됩니다.');
      return;
    }

    try {
      setState(() => _isSigningIn = true);

      if (!_googleInitialized) {
        await GoogleSignIn.instance.initialize(serverClientId: _webClientId);
        _googleInitialized = true;
      }

      // Already signed in with FirebaseAuth -> reuse session
      final existingAuthUser = FirebaseAuth.instance.currentUser;
      if (existingAuthUser != null) {
        await _persistUser(existingAuthUser);
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/home');
        return;
      }

      final GoogleSignInAccount googleUser =
          await GoogleSignIn.instance.authenticate();

      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      if (googleAuth.idToken == null) {
        throw Exception('Google 로그인 실패: idToken이 null 입니다.');
      }

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      final User? user = userCredential.user;
      if (user == null) {
        throw Exception('Firebase 로그인 실패: user == null');
      }

      await _persistUser(user);

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } on GoogleSignInException catch (e, st) {
      debugPrint('[Google Login Error] $e\n$st');

      final message = switch (e.code) {
        GoogleSignInExceptionCode.canceled => 'Google 로그인이 취소되었습니다.',
        GoogleSignInExceptionCode.interrupted =>
          'Google 로그인이 중단되었습니다.',
        GoogleSignInExceptionCode.uiUnavailable =>
          '이 기기에서 Google 로그인 UI를 사용할 수 없습니다.',
        _ => 'Google 로그인 오류: $e',
      };
      _showSnack(message);
    } catch (e, st) {
      debugPrint('[Google Login Error] $e\n$st');
      _showSnack('Google 로그인 오류: $e');
    } finally {
      if (mounted) setState(() => _isSigningIn = false);
    }
  }

  void _onGuestLogin() {
    Navigator.pushNamed(context, '/guest_login');
  }

  Future<void> _persistUser(User user) async {
    final String uid = user.uid;
    final now = DateTime.now();

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
      FirestoreService.setCurrentUser(newUser);
    } else {
      final updated = existing.copyWith(lastLoginAt: now);
      await FirestoreService.updateUser(updated);
      FirestoreService.setCurrentUser(updated);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Image.asset('assets/images/logo_done_big.png', height: 180),
              const SizedBox(height: 64),

              PrimaryButton(
                text: '회원가입 없이 둘러보기',
                onPressed: _continueAsGuest,
              ),

              const SizedBox(height: AppSpacing.md),

              SizedBox(
                height: 48,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: AppColors.border.withOpacity(0.8),
                      width: 1,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _isSigningIn ? null : _onGoogleLogin,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/google_logo.png',
                        width: 18,
                        height: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Google 계정으로 로그인',
                        style: AppTextStyles.body1.copyWith(
                          color: AppColors.primaryText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}
