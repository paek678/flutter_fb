import 'package:flutter/material.dart';

// --- 각 화면 import ---
import '../features/auth/presentation/login_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/auction/presentation/auction_itemDetail_screen.dart';
import '../features/auth/presentation/find_id_screen.dart';
import '../features/auth/presentation/find_password_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/auth/presentation/guest_login_screen.dart';
import '../features/community/presentation/community_list_screen.dart';
import '../features/community/presentation/community_post_write_screen.dart';
import '../features/board/presentation/board_write_screen.dart';
import '../features/community/presentation/community_detail_screen.dart';
import '../features/community/model/community_post.dart';
import '../features/community/repository/community_repository.dart';
import '../features/auction/presentation/auction_favorite_screen.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => const LoginScreen());

      case '/home':
        return MaterialPageRoute(builder: (_) => const HomeScreen());

      case '/register':
        return MaterialPageRoute(builder: (_) => const RegisterScreen());

      case '/find_id':
        return MaterialPageRoute(builder: (_) => const FindIdScreen());

      case '/find_password':
        return MaterialPageRoute(builder: (_) => const FindPasswordScreen());

      case '/guest_login':
        return MaterialPageRoute(builder: (_) => const GuestLoginScreen());

      case '/settings':
        return MaterialPageRoute(builder: (_) => const SettingsScreen());

      case '/auction_item_detail':
        return MaterialPageRoute(
          builder: (_) => const AuctionItemDetailScreen(),
          settings: settings,
        );
      case '/auction_favorites':
        return MaterialPageRoute(
          builder: (_) => const AuctionFavoriteScreen(),
          settings: settings,
        );
      // 공지 작성
      case '/notice_write':
        return MaterialPageRoute(
          builder: (_) => const NoticeWriteScreen(),
          settings: settings,
        );

      // 커뮤니티 리스트
      case '/community':
        return MaterialPageRoute(builder: (_) => const CommunityListScreen());

      // 커뮤니티 글 작성
      case '/community_post_write':
        return MaterialPageRoute(
          builder: (_) => const CommunityPostWriteScreen(),
          settings: settings,
        );

      // 커뮤니티 글 상세
      case '/community_detail':
        {
          final args = settings.arguments;

          if (args is Map<String, dynamic>) {
            final post = args['post'] as CommunityPost?;
            // 💡 수정 1: 타입 캐스팅을 CommunityRepository 인터페이스로 변경
            final repo = args['repo'] as CommunityRepository?;

            if (post != null && repo != null) {
              return MaterialPageRoute(
                builder: (_) => CommunityDetailScreen(post: post, repo: repo),
                settings: settings,
              );
            }
          }

          // post만 넘어온 경우 방어 (repo가 누락된 경우)
          if (args is CommunityPost) {
            return MaterialPageRoute(
              builder: (_) => CommunityDetailScreen(
                post: args,
                // 💡 수정 2: InMemoryCommunityRepository() 대신 Firestore 구현체 사용
                repo: FirestoreCommunityRepository(),
              ),
              settings: settings,
            );
          }

          return MaterialPageRoute(
            builder: (_) =>
                const Scaffold(body: Center(child: Text('잘못된 커뮤니티 글 데이터입니다.'))),
          );
        }

      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('404 - 페이지를 찾을 수 없습니다.')),
          ),
        );
    }
  }
}
