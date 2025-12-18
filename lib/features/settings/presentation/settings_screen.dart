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

  List<Widget> _generalSettings() => [
        _SwitchTile(
          title: '다크 모드',
          subtitle: '테마를 어두운 모드로 변경',
          value: _isDarkMode,
          onChanged: (value) {
            setState(() => _isDarkMode = value);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  value ? '다크 모드가 켜졌습니다.' : '다크 모드가 꺼졌습니다.',
                ),
                duration: const Duration(seconds: 1),
              ),
            );
          },
        ),
        _SwitchTile(
          title: '알림 받기',
          subtitle: '게임 이벤트/업데이트 알림 수신',
          value: _notificationsEnabled,
          onChanged: (value) => setState(() => _notificationsEnabled = value),
        ),
      ];

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
          const _SectionTitle('일반 설정'),
          const SizedBox(height: 10),
          ..._generalSettings(),
          const Divider(height: 30),
          const _SectionTitle('계정'),
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
          _ConfirmActionTile(
            icon: Icons.logout,
            title: '로그아웃',
            enabled: !_isLoggingOut,
            onConfirm: _logout,
            loading: _isLoggingOut,
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
    );
  }
}

class _ConfirmActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool enabled;
  final Future<void> Function() onConfirm;
  final bool loading;

  const _ConfirmActionTile({
    required this.icon,
    required this.title,
    required this.enabled,
    required this.onConfirm,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      enabled: enabled,
      onTap: () {
        showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(title),
            content: Text('$title 하시겠습니까?'),
            actions: [
              TextButton(
                onPressed: loading ? null : () => Navigator.pop(dialogContext),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: loading
                    ? null
                    : () async {
                        Navigator.pop(dialogContext);
                        await onConfirm();
                      },
                child: loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('확인'),
              ),
            ],
          ),
        );
      },
    );
  }
}
