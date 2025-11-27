import 'package:flutter/material.dart';
import './character_search_page.dart';

class TopAppBarCharacterSearchScreen extends StatelessWidget {
  final String query;

  const TopAppBarCharacterSearchScreen({super.key, required this.query});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('캐릭터 검색')),
      body: CharacterSearchTab(initialQuery: query),
    );
  }
}
