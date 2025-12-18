// lib/features/settings/presentation/settings_screen.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_fb/core/services/firebase_service.dart';
import 'package:google_sign_in/google_sign_in.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDarkMode = false;
  bool _notificationsEnabled = true;
  bool _isLoggingOut = false;

  Future<void> _logout() async {
    if (_isLoggingOut) return;

    setState(() => _isLoggingOut = true);
    try {
      await FirebaseAuth.instance.signOut();
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {
        // Firebase sign-out is the source of truth; ignore provider errors.
      }

      FirestoreService.setCurrentUser(null);

      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
    } finally {
      if (mounted) setState(() => _isLoggingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            '일반 설정',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          SwitchListTile(
            title: const Text('다크 모드'),
            subtitle: const Text('테마를 어두운 모드로 변경'),
            value: _isDarkMode,
            onChanged: (value) {
              setState(() => _isDarkMode = value);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _isDarkMode ? '다크 모드가 켜졌습니다.' : '다크 모드가 꺼졌습니다.',
                  ),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
          SwitchListTile(
            title: const Text('알림 받기'),
            subtitle: const Text('게임 이벤트/업데이트 알림 수신'),
            value: _notificationsEnabled,
            onChanged: (value) => setState(() => _notificationsEnabled = value),
          ),
          const Divider(height: 30),
          const Text(
            '계정',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          ListTile(
            leading: const Icon(Icons.lock),
            title: const Text('비밀번호 변경'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('비밀번호 변경 기능은 준비 중입니다.'),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('로그아웃'),
            enabled: !_isLoggingOut,
            onTap: () {
              showDialog<void>(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: const Text('로그아웃'),
                  content: const Text('정말 로그아웃 하시겠습니까?'),
                  actions: [
                    TextButton(
                      onPressed: _isLoggingOut
                          ? null
                          : () => Navigator.pop(dialogContext),
                      child: const Text('취소'),
                    ),
                    TextButton(
                      onPressed: _isLoggingOut
                          ? null
                          : () async {
                              Navigator.pop(dialogContext);
                              await _logout();
                            },
                      child: _isLoggingOut
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('로그아웃'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
