import 'package:flutter/material.dart';
import 'package:flutter_fb/core/theme/app_colors.dart';

/// 소제목(Subtitle)이 있는 버전의 공통 컨테이너
/// header → subtitle → children 구조
class CustomContainerWithSubtitle extends StatelessWidget {
  final Widget? header; // 상단 헤더 (예: 제목행)
  final Widget? subtitle; // 헤더 아래 소제목 (회색 배경 영역)
  final List<Widget> children;
  final EdgeInsetsGeometry? padding;
  const CustomContainerWithSubtitle({
    super.key,
    this.header,
    this.subtitle,
    required this.children,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.border,
          width: 0.5,
          strokeAlign: BorderSide.strokeAlignInside,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ 헤더
          if (header != null)
            Padding(padding: const EdgeInsets.all(12), child: header!),

          // ✅ 소제목 영역 (회색 배경)
          if (subtitle != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              color: const Color(0xFFF7F7F7),
              child: subtitle!,
            ),

          // ✅ 내용
          Padding(
            padding: padding ?? const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}
