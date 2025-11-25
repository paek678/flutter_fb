// lib/features/community/presentation/community_post_write_screen.dart
import 'package:flutter/material.dart';

// 공통 테마
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

// 커뮤니티 도메인
import '../model/community_post.dart';
import '../model/post_category.dart';
// 💡 CommunityRepository 인터페이스 또는 추상 클래스 import
import '../repository/community_repository.dart'; 

class CommunityPostWriteScreen extends StatefulWidget {
  const CommunityPostWriteScreen({super.key});

  @override
  State<CommunityPostWriteScreen> createState() =>
      _CommunityPostWriteScreenState();
}

class _CommunityPostWriteScreenState extends State<CommunityPostWriteScreen> {
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _submitting = false;

  static const int _titleMax = 60;
  static const int _contentMin = 10;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    // 💡 수정: Repository 타입을 CommunityRepository로 변경
    final repo = ModalRoute.of(context)!.settings.arguments as CommunityRepository?;
    
    if (repo == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('레포지토리를 찾을 수 없습니다.')),
      );
      return;
    }

    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _submitting = true);

    // 💡 docId를 null로 설정하여 Firestore에서 자동 생성되도록 유도
    // (CommunityPost 모델에 docId 필드가 있다고 가정)
    final post = CommunityPost(
      id: 0, // Firestore 문서 ID는 생성 시점에 null
      title: _titleCtrl.text.trim(),
      content: _contentCtrl.text.trim(),
      author: '나', // TODO: 로그인 사용자명으로 교체
      createdAt: DateTime.now(),
      category: PostCategory.general, // 카테고리 고정
      views: 0,
      likes: 0, // 좋아요 필드 추가 (이전 코드에서 누락되어 있었다면 추가)
      commentCount: 0,
    );

    try {
      final created = await repo.createPost(post);
      
      if (!mounted) return;
      
      // 💡 생성된 게시글 객체를 목록 화면으로 반환
      Navigator.pop(context, created); 
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('작성 실패: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('게시물 작성')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 960),
                child: Column(
                  children: [
                    Expanded(
                      child: ListView(
                        children: [
                          // 제목
                          TextFormField(
                            controller: _titleCtrl,
                            maxLength: _titleMax,
                            decoration: InputDecoration(
                              labelText: '제목',
                              hintText: '제목을 입력하세요 (최대 60자)',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              isDense: true,
                            ),
                            validator: (v) {
                              final s = v?.trim() ?? '';
                              if (s.isEmpty) return '제목을 입력하세요.';
                              return null;
                            },
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 12),

                          // 내용
                          TextFormField(
                            controller: _contentCtrl,
                            decoration: InputDecoration(
                              hintText: '내용을 작성하세요. 엔터로 줄바꿈 가능합니다.',
                              alignLabelWithHint: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            keyboardType: TextInputType.multiline,
                            maxLines: 12,
                            minLines: 8,
                            validator: (v) {
                              final s = v?.trim() ?? '';
                              if (s.length < _contentMin) {
                                return '내용은 최소 $_contentMin자 이상 입력하세요.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 8),

                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 16,
                                color: AppColors.secondaryText,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '작성한 내용은 저장 후 수정할 수 있어요.',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.secondaryText,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // 하단 작성 완료 버튼 (공지 작성 / PrimaryButton 톤 맞춤)
                    SizedBox(
                      height: 48,
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitting ? null : _submit,
                        style: ButtonStyle(
                          backgroundColor:
                              MaterialStateProperty.resolveWith<Color>((
                            states,
                          ) {
                            if (states.contains(MaterialState.disabled)) {
                              return AppColors.border;
                            }
                            if (states.contains(MaterialState.pressed)) {
                              return AppColors.primaryText.withOpacity(0.9);
                            }
                            if (states.contains(MaterialState.hovered)) {
                              return AppColors.secondaryText;
                            }
                            return AppColors.primaryText;
                          }),
                          foregroundColor: MaterialStateProperty.all<Color>(
                            Colors.white,
                          ),
                          shape: MaterialStateProperty.all(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          textStyle: MaterialStateProperty.all(
                            AppTextStyles.body1.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          elevation: MaterialStateProperty.all(0),
                        ),
                        child: _submitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('작성 완료'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}