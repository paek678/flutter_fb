import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_fb/core/services/firebase_service.dart';
import 'package:flutter_fb/features/auth/model/app_user.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/custom_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLogin() {
    // TODO: 실제 로그인 연동
    Navigator.pushReplacementNamed(context, '/home');
  }

  static const String _webClientId =
      '800134555306-orq1jhqs4l8qim0vmo20tovkagovs5ld.apps.googleusercontent.com';

  Future<void> _onGoogleLogin() async {
    // 데스크톱/Web에서 눌렀을 때는 막기 (선택 사항)
    if (!Platform.isAndroid && !Platform.isIOS) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Google 로그인은 모바일(Android/iOS)에서만 지원됩니다.')),
      );
      return;
    }

    try {
      // 🔹 0) serverClientId로 GoogleSignIn 초기화 (★ 새로 추가된 부분)
      await GoogleSignIn.instance.initialize(serverClientId: _webClientId);

      // 1) Google Sign-In 플로우 시작
      final GoogleSignInAccount? googleUser = await GoogleSignIn.instance
          .authenticate();

      if (googleUser == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Google 로그인 취소됨')));
        return;
      }

      // 2) 토큰 가져오기 (여기서는 authentication 에서 idToken 사용)
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        // accessToken은 Firebase 로그인만 쓸 거면 굳이 없어도 됨
      );

      // 3) Firebase Auth 로그인
      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithCredential(credential);

      final User? user = userCredential.user;
      if (user == null) {
        throw Exception('Firebase 로그인 실패: user == null');
      }

      final String uid = user.uid;
      final now = DateTime.now();

      // 4) Firestore users 컬렉션에서 uid로 조회
      final existing = await FirestoreService.getUserByUid(uid);

      if (existing == null) {
        // 새 유저 문서 생성
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
      } else {
        // 기존 유저면 마지막 로그인 시간만 갱신
        final updated = existing.copyWith(lastLoginAt: now);
        await FirestoreService.updateUser(updated);
      }

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e, st) {
      // 디버깅용 로그
      // ignore: avoid_print
      print('[Google Login Error] $e\n$st');

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Google 로그인 중 오류 발생: $e')));
    }
  }

  void _onGuestLogin() {
    // 🔹 게스트 팝업 화면으로 이동 (이제 /home 말고 /guest_login 으로 감)
    Navigator.pushNamed(context, '/guest_login');
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
              // 로고/타이틀
              Text(
                '로그인',
                textAlign: TextAlign.center,
                style: AppTextStyles.h1.copyWith(color: AppColors.primaryText),
              ),
              const SizedBox(height: AppSpacing.xl),

              // 이메일 입력
              CustomTextField(hintText: '이메일 주소', controller: _emailController),
              const SizedBox(height: AppSpacing.md),

              // 비밀번호 입력 (지금 CustomTextField에 obscureText가 없으니 그대로 사용)
              CustomTextField(
                hintText: '비밀번호',
                controller: _passwordController,
              ),
              const SizedBox(height: AppSpacing.lg),

              // 기본 로그인 버튼
              PrimaryButton(text: '로그인', onPressed: _onLogin),

              const SizedBox(height: AppSpacing.md),

              // 구분선 "또는"
              _buildDividerWithText('또는'),

              const SizedBox(height: AppSpacing.md),

              // Google 로그인 버튼 (흰 배경, 로고 + 텍스트)
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
                  onPressed: _onGoogleLogin,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 실제론 assets에 구글 아이콘 하나 넣어라.
                      // 예: assets/images/google_logo.png 등록 후 아래 사용
                      Image.asset(
                        'assets/images/google_logo.png',
                        width: 18,
                        height: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Google 계정으로 로그인',
                        style: AppTextStyles.body2.copyWith(
                          color: AppColors.primaryText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // 회원/찾기 링크 영역
              _buildAuthLinksRow(context),

              const SizedBox(height: AppSpacing.md),

              // 게스트 로그인
              Center(
                child: TextButton.icon(
                  onPressed: _onGuestLogin,
                  icon: const Icon(Icons.person_outline),
                  label: Text(
                    '게스트로 둘러보기',
                    style: AppTextStyles.body1.copyWith(
                      color: AppColors.secondaryText,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.secondaryText,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDividerWithText(String text) {
    return Row(
      children: [
        Expanded(
          child: Container(height: 1, color: AppColors.border.withOpacity(0.6)),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: AppTextStyles.caption.copyWith(color: AppColors.secondaryText),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(height: 1, color: AppColors.border.withOpacity(0.6)),
        ),
      ],
    );
  }

  Widget _buildAuthLinksRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _linkButton(
          label: '회원가입',
          onPressed: () => Navigator.pushNamed(context, '/register'),
        ),
        _verticalDivider(),
        _linkButton(
          label: 'ID 찾기',
          onPressed: () => Navigator.pushNamed(context, '/find_id'),
        ),
        _verticalDivider(),
        _linkButton(
          label: '비밀번호 찾기',
          onPressed: () => Navigator.pushNamed(context, '/find_password'),
        ),
      ],
    );
  }

  Widget _linkButton({required String label, required VoidCallback onPressed}) {
    return TextButton(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        minimumSize: const Size(0, 0),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      onPressed: onPressed,
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: AppColors.primaryText,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _verticalDivider() {
    return Container(
      width: 1,
      height: 14,
      color: AppColors.secondaryText.withOpacity(0.4),
    );
  }
}
