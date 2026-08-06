import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/snackbar_utils.dart';

class LearnScreen extends StatefulWidget {
  const LearnScreen({super.key});

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  final PageController _pageController = PageController();
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All Topics';
  String _searchQuery = '';
  bool _isSearchVisible = false;

  final Map<int, bool> _likedMap = {};
  final Map<int, bool> _savedMap = {};

  final List<String> _categories = [
    'All Topics',
    'Java',
    'Python',
    'Flutter',
    'AI',
    'React',
  ];

  final List<Map<String, String>> _allReelsData = [
    {
      'id': 'reel-1',
      'title': 'Mastering Flutter 3.27 Glassmorphism Design',
      'author': 'Sarah Jenkins • Senior UI Engineer',
      'likes': '12.4k',
      'duration': '0:45',
      'category': 'Flutter',
    },
    {
      'id': 'reel-2',
      'title': 'Top 5 Python Async Asyncio Gotchas in 2025',
      'author': 'Alex Rivers • Staff Backend Architect',
      'likes': '9.8k',
      'duration': '1:15',
      'category': 'Python',
    },
    {
      'id': 'reel-3',
      'title': 'Cracking System Design: Rate Limiting Algorithms',
      'author': 'Dr. Marcus Vance • Tech Lead',
      'likes': '24.1k',
      'duration': '1:00',
      'category': 'AI',
    },
    {
      'id': 'reel-4',
      'title': 'Java 21 Virtual Threads & Structured Concurrency',
      'author': 'David Chen • JVM Specialist',
      'likes': '15.3k',
      'duration': '0:55',
      'category': 'Java',
    },
    {
      'id': 'reel-5',
      'title': 'React 19 Server Actions & Compiler Deep Dive',
      'author': 'Elena Rostova • Frontend Architect',
      'likes': '18.7k',
      'duration': '1:10',
      'category': 'React',
    },
    {
      'id': 'reel-6',
      'title': 'Prompt Engineering & Fine-tuning LLMs with RAG',
      'author': 'Aria Sterling • AI Researcher',
      'likes': '31.2k',
      'duration': '1:30',
      'category': 'AI',
    },
  ];

  List<Map<String, String>> get _filteredReels {
    return _allReelsData.where((reel) {
      final matchesCategory = _selectedCategory == 'All Topics' ||
          reel['category'] == _selectedCategory;
      final q = _searchQuery.trim().toLowerCase();
      final matchesSearch = q.isEmpty ||
          reel['title']!.toLowerCase().contains(q) ||
          reel['author']!.toLowerCase().contains(q) ||
          reel['category']!.toLowerCase().contains(q);
      return matchesCategory && matchesSearch;
    }).toList();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reels = _filteredReels;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Vertical Reels PageView or Empty State
          reels.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_off_rounded,
                            size: 64, color: Colors.white38),
                        const SizedBox(height: 16),
                        Text(
                          'No reels match "$_searchQuery" in $_selectedCategory',
                          textAlign: TextAlign.center,
                          style: AppTypography.titleMedium.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _selectedCategory = 'All Topics';
                              _searchQuery = '';
                              _searchController.clear();
                              _isSearchVisible = false;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Reset Filters'),
                        ),
                      ],
                    ),
                  ),
                )
              : PageView.builder(
                  key: ValueKey('reels_${_selectedCategory}_$_searchQuery'),
                  controller: _pageController,
                  scrollDirection: Axis.vertical,
                  itemCount: reels.length,
                  itemBuilder: (context, index) {
                    final reel = reels[index];
                    final reelKey = reel['id'].hashCode;
                    final isLiked = _likedMap[reelKey] ?? false;
                    final isSaved = _savedMap[reelKey] ?? false;

                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        // Background gradient
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary.withValues(alpha: 0.8),
                                Colors.black,
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.play_circle_fill_rounded,
                                  size: 80,
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white12,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.white24),
                                  ),
                                  child: Text(
                                    reel['category']!,
                                    style: AppTypography.codeMono.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Bottom Gradient Mask
                        Positioned.fill(
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.transparent, Colors.black87],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                stops: [0.5, 1.0],
                              ),
                            ),
                          ),
                        ),

                        // Left Side Overlay Info
                        Positioned(
                          bottom: 90,
                          left: 20,
                          right: 90,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                child: Text(
                                  reel['duration']!,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(height: 10),
                              GestureDetector(
                                onTap: () => showComingSoonSnackBar(
                                    context, 'Author Profile'),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white24,
                                      ),
                                      child: const Icon(Icons.person,
                                          color: Colors.white, size: 18),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        reel['author']!,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                reel['title']!,
                                style: AppTypography.titleMedium.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  shape: const StadiumBorder(),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                ),
                                icon: const Icon(Icons.psychology_rounded,
                                    size: 18),
                                label: const Text('Practice This Skill',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12)),
                                onPressed: () =>
                                    context.push('/interview/setup'),
                              ),
                            ],
                          ),
                        ),

                        // Right Interaction Column
                        Positioned(
                          bottom: 100,
                          right: 16,
                          child: Column(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  setState(
                                      () => _likedMap[reelKey] = !isLiked);
                                },
                                child: Column(
                                  children: [
                                    Icon(
                                      isLiked
                                          ? Icons.favorite_rounded
                                          : Icons.favorite_border_rounded,
                                      color: isLiked
                                          ? Colors.redAccent
                                          : Colors.white,
                                      size: 32,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      isLiked ? '12.5k' : reel['likes']!,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                              GestureDetector(
                                onTap: () {
                                  setState(
                                      () => _savedMap[reelKey] = !isSaved);
                                  ScaffoldMessenger.of(context)
                                      .clearSnackBars();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(isSaved
                                          ? 'Removed from Saved'
                                          : 'Reel Saved to Bookmarks'),
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                },
                                child: Column(
                                  children: [
                                    Icon(
                                      isSaved
                                          ? Icons.bookmark_rounded
                                          : Icons.bookmark_border_rounded,
                                      color: isSaved
                                          ? AppColors.tertiaryContainer
                                          : Colors.white,
                                      size: 32,
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Save',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                              GestureDetector(
                                onTap: () => showComingSoonSnackBar(
                                    context, 'Share Reel'),
                                child: const Column(
                                  children: [
                                    Icon(Icons.share_rounded,
                                        color: Colors.white, size: 32),
                                    SizedBox(height: 4),
                                    Text(
                                      'Share',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),

          // Top Header Category & Search Bar
          Positioned(
            top: 44,
            left: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _categories.map((cat) {
                            final isSelected = cat == _selectedCategory;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                selected: isSelected,
                                label: Text(cat),
                                labelStyle: TextStyle(
                                  color:
                                      isSelected ? Colors.black : Colors.white,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  fontSize: 12,
                                ),
                                backgroundColor:
                                    Colors.white.withValues(alpha: 0.2),
                                selectedColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                onSelected: (_) {
                                  setState(() => _selectedCategory = cat);
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(
                        _isSearchVisible
                            ? Icons.close_rounded
                            : Icons.search_rounded,
                        color: Colors.white,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white24,
                      ),
                      onPressed: () {
                        setState(() {
                          _isSearchVisible = !_isSearchVisible;
                          if (!_isSearchVisible) {
                            _searchController.clear();
                            _searchQuery = '';
                          }
                        });
                      },
                    ),
                  ],
                ),
                if (_isSearchVisible) ...[
                  const SizedBox(height: 10),
                  TextField(
                    controller: _searchController,
                    autofocus: true,
                    style: const TextStyle(color: Colors.white),
                    onChanged: (val) {
                      setState(() => _searchQuery = val);
                    },
                    decoration: InputDecoration(
                      hintText: 'Search reels, topics, authors...',
                      hintStyle: const TextStyle(color: Colors.white60),
                      prefixIcon:
                          const Icon(Icons.search_rounded, color: Colors.white60),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded,
                                  color: Colors.white60),
                              onPressed: () {
                                setState(() {
                                  _searchController.clear();
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                      fillColor: Colors.black87,
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: const BorderSide(color: Colors.white38),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: const BorderSide(color: Colors.white38),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: const BorderSide(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
