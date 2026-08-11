import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';
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
  
  int _currentPageIndex = 0;
  String _selectedCategory = 'All Topics';
  bool _isSwiping = false;

  final Map<int, bool> _likedMap = {};
  final Map<int, bool> _savedMap = {};
  final Map<int, bool> _followingMap = {};

  final List<String> _categories = [
    'All Topics',
    'Flutter',
    'Python',
    'System Design',
    'Java',
    'React',
    'AI & ML',
  ];

  static const String _reelVideoUrl =
      'https://s3.ap-south-1.amazonaws.com/cranesdigitalacademy.com/videos/X0DPD7US66NPFMQX.mp4';

  final List<Map<String, String>> _allReelsData = [
    {
      'id': 'reel-1',
      'title': 'Mastering Flutter 3.27 Glassmorphism & Micro-animations',
      'author': 'Sarah Jenkins',
      'role': 'Senior UI Engineer',
      'likes': '14.8k',
      'comments': '482',
      'duration': '0:45',
      'category': 'Flutter',
      'music': 'Cranes Digital Academy · UI Mastery Vol. 1',
    },
    {
      'id': 'reel-2',
      'title': 'Top 5 Python Asyncio & Concurrency Gotchas in 2025',
      'author': 'Alex Rivers',
      'role': 'Staff Backend Architect',
      'likes': '18.2k',
      'comments': '621',
      'duration': '1:15',
      'category': 'Python',
      'music': 'Alex Rivers · Async Python Insights',
    },
    {
      'id': 'reel-3',
      'title': 'Cracking System Design: Rate Limiting & Token Bucket Algorithms',
      'author': 'Dr. Marcus Vance',
      'role': 'Principal Tech Lead',
      'likes': '32.1k',
      'comments': '1.2k',
      'duration': '1:00',
      'category': 'System Design',
      'music': 'System Design Blueprint · Episode 12',
    },
    {
      'id': 'reel-4',
      'title': 'Java 21 Virtual Threads & High-Throughput Microservices',
      'author': 'David Chen',
      'role': 'JVM Specialist',
      'likes': '15.9k',
      'comments': '340',
      'duration': '0:55',
      'category': 'Java',
      'music': 'Java Tech Bytes · Spring Boot 3.2',
    },
    {
      'id': 'reel-5',
      'title': 'React 19 Server Actions & Compiler Optimization',
      'author': 'Elena Rostova',
      'role': 'Frontend Architect',
      'likes': '22.4k',
      'comments': '890',
      'duration': '1:10',
      'category': 'React',
      'music': 'React Conf 2025 · Deep Dive',
    },
    {
      'id': 'reel-6',
      'title': 'Prompt Engineering & Fine-tuning LLMs with RAG Systems',
      'author': 'Aria Sterling',
      'role': 'Lead AI Researcher',
      'likes': '45.7k',
      'comments': '2.1k',
      'duration': '1:30',
      'category': 'AI & ML',
      'music': 'Aria Sterling · GenAI Architectures',
    },
  ];

  List<Map<String, String>> get _filteredReels {
    return _allReelsData.where((reel) {
      return _selectedCategory == 'All Topics' ||
          reel['category'] == _selectedCategory;
    }).toList();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Fast smooth swipe helper with ultra-fluid curve
  void _onScrollNotification(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification && !_isSwiping) {
      final delta = notification.scrollDelta ?? 0;
      if (delta.abs() > 16) {
        if (delta > 0 && _currentPageIndex < _filteredReels.length - 1) {
          _isSwiping = true;
          _pageController
              .nextPage(
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.fastOutSlowIn)
              .then((_) => _isSwiping = false);
        } else if (delta < 0 && _currentPageIndex > 0) {
          _isSwiping = true;
          _pageController
              .previousPage(
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.fastOutSlowIn)
              .then((_) => _isSwiping = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final reels = _filteredReels;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final topInset = MediaQuery.of(context).padding.top;
    
    // Position overlay 122px from bottom so Glass Card and Share button hover 25px comfortably above the nav dock
    final double overlayBottomMargin = 122.0 + (bottomInset > 0 ? 6.0 : 0.0);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── VERTICAL INSTAGRAM REELS PAGEVIEW (Ultra-fast, smooth snapping) ────
          reels.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.video_library_outlined,
                            size: 64, color: Colors.white38),
                        const SizedBox(height: 16),
                        Text(
                          'No reels in $_selectedCategory',
                          textAlign: TextAlign.center,
                          style: AppTypography.titleMedium.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            setState(() => _selectedCategory = 'All Topics');
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
              : NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    _onScrollNotification(notification);
                    return false;
                  },
                  child: PageView.builder(
                    key: ValueKey('reels_pv_$_selectedCategory'),
                    controller: _pageController,
                    physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                    scrollDirection: Axis.vertical,
                    itemCount: reels.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPageIndex = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      final reel = reels[index];
                      final reelKey = reel['id'].hashCode;
                      final isLiked = _likedMap[reelKey] ?? false;
                      final isSaved = _savedMap[reelKey] ?? false;
                      final isFollowing = _followingMap[reelKey] ?? false;
                      final isCurrentPage = index == _currentPageIndex;

                      final reelViewWidget = _ReelItemView(
                        reel: reel,
                        videoUrl: _reelVideoUrl,
                        isCurrentPage: isCurrentPage,
                        isLiked: isLiked,
                        isSaved: isSaved,
                        isFollowing: isFollowing,
                        overlayBottomMargin: overlayBottomMargin,
                        onLikeToggle: () {
                          setState(() => _likedMap[reelKey] = !isLiked);
                        },
                        onSaveToggle: () {
                          setState(() => _savedMap[reelKey] = !isSaved);
                          ScaffoldMessenger.of(context).clearSnackBars();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(!isSaved
                                  ? 'Reel saved to Bookmarks 🔖'
                                  : 'Removed from Bookmarks'),
                              duration: const Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        onFollowToggle: () {
                          setState(() => _followingMap[reelKey] = !isFollowing);
                          ScaffoldMessenger.of(context).clearSnackBars();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(!isFollowing
                                  ? 'Following ${reel['author']}'
                                  : 'Unfollowed ${reel['author']}'),
                              duration: const Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      );

                      return AnimatedBuilder(
                        animation: _pageController,
                        builder: (context, child) {
                          double pageOffset = 0.0;
                          if (_pageController.hasClients &&
                              _pageController.position.haveDimensions) {
                            pageOffset = (_pageController.page ?? _currentPageIndex.toDouble()) - index;
                          } else {
                            pageOffset = (_currentPageIndex - index).toDouble();
                          }

                          final double scale = (1.0 - (pageOffset.abs() * 0.08)).clamp(0.92, 1.0);
                          final double opacity = (1.0 - (pageOffset.abs() * 0.30)).clamp(0.5, 1.0);

                          return Transform.scale(
                            scale: scale,
                            child: Opacity(
                              opacity: opacity,
                              child: child,
                            ),
                          );
                        },
                        child: reelViewWidget,
                      );
                    },
                  ),
                ),

          // ── TOP HEADER BAR (Clean Instagram Reels Header) ─────────────
          Positioned(
            top: topInset + 6,
            left: 16,
            right: 16,
            child: Row(
              children: [
                const Text(
                  'Reels',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    shadows: [
                      Shadow(blurRadius: 8, color: Colors.black87),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: _categories.map((cat) {
                        final isSelected = cat == _selectedCategory;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            selected: isSelected,
                            label: Text(cat),
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.black : Colors.white,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              fontSize: 11.5,
                            ),
                            backgroundColor: Colors.black38,
                            selectedColor: Colors.white,
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(100),
                              side: BorderSide(
                                color: isSelected ? Colors.white : Colors.white24,
                              ),
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// REEL ITEM VIEW WITH HIGH-PERFORMANCE VIDEO PLAYER
// ─────────────────────────────────────────────────────────────
class _ReelItemView extends StatefulWidget {
  final Map<String, String> reel;
  final String videoUrl;
  final bool isCurrentPage;
  final bool isLiked;
  final bool isSaved;
  final bool isFollowing;
  final double overlayBottomMargin;
  final VoidCallback onLikeToggle;
  final VoidCallback onSaveToggle;
  final VoidCallback onFollowToggle;

  const _ReelItemView({
    required this.reel,
    required this.videoUrl,
    required this.isCurrentPage,
    required this.isLiked,
    required this.isSaved,
    required this.isFollowing,
    required this.overlayBottomMargin,
    required this.onLikeToggle,
    required this.onSaveToggle,
    required this.onFollowToggle,
  });

  @override
  State<_ReelItemView> createState() => _ReelItemViewState();
}

class _ReelItemViewState extends State<_ReelItemView> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _showPlayPauseIndicator = false;

  // Double-tap heart burst animation
  bool _showHeartAnimation = false;
  Offset _heartPos = Offset.zero;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    try {
      await _controller.initialize();
      await _controller.setLooping(true);
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        if (widget.isCurrentPage) {
          _controller.play();
          _isPlaying = true;
        }
      }
    } catch (_) {}
  }

  @override
  void didUpdateWidget(covariant _ReelItemView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isInitialized) {
      if (widget.isCurrentPage && !_controller.value.isPlaying) {
        _controller.play();
        setState(() => _isPlaying = true);
      } else if (!widget.isCurrentPage && _controller.value.isPlaying) {
        _controller.pause();
        setState(() => _isPlaying = false);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (!_isInitialized) return;
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
        _isPlaying = false;
      } else {
        _controller.play();
        _isPlaying = true;
      }
      _showPlayPauseIndicator = true;
    });

    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) {
        setState(() => _showPlayPauseIndicator = false);
      }
    });
  }

  void _onDoubleTap(TapDownDetails details) {
    if (!widget.isLiked) {
      widget.onLikeToggle();
    }
    setState(() {
      _heartPos = details.localPosition;
      _showHeartAnimation = true;
    });
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() => _showHeartAnimation = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return GestureDetector(
      onTap: _togglePlayPause,
      onDoubleTapDown: _onDoubleTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── 1. Video Player (High Quality Cover Fit) ─────────
          _isInitialized
              ? SizedBox.expand(
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _controller.value.size.width > 0
                          ? _controller.value.size.width
                          : size.width,
                      height: _controller.value.size.height > 0
                          ? _controller.value.size.height
                          : size.height,
                      child: VideoPlayer(_controller),
                    ),
                  ),
                )
              : Container(
                  color: Colors.black,
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 2.5,
                    ),
                  ),
                ),

          // ── 2. Top & Bottom Gradient Scrim for Legibility ──────
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black54,
                    Colors.transparent,
                    Colors.transparent,
                    Color(0xF7000000),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.0, 0.18, 0.45, 1.0],
                ),
              ),
            ),
          ),

          // ── 3. Animated Play / Pause Center Icon Indicator ──────
          if (_showPlayPauseIndicator)
            Center(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _showPlayPauseIndicator ? 1.0 : 0.0,
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isPlaying ? Icons.play_arrow_rounded : Icons.pause_rounded,
                    color: Colors.white,
                    size: 44,
                  ),
                ),
              ),
            ),

          // ── 4. Double Tap Heart Burst Overlay ──────────────────
          if (_showHeartAnimation)
            Positioned(
              left: _heartPos.dx - 40,
              top: _heartPos.dy - 40,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.5, end: 1.2),
                duration: const Duration(milliseconds: 400),
                builder: (context, scale, child) {
                  return Transform.scale(
                    scale: scale,
                    child: const Icon(
                      Icons.favorite_rounded,
                      color: Colors.redAccent,
                      size: 80,
                    ),
                  );
                },
              ),
            ),

          // ── 5. Bottom-Left Glassmorphic Info Card ───────
          Positioned(
            bottom: widget.overlayBottomMargin,
            left: 12,
            right: 68,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0x99101014),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.16),
                      width: 1.0,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black45,
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Reel Title & Description
                      Text(
                        widget.reel['title']!,
                        style: AppTypography.titleMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 8),

                      // Skill Badge Pill & Audio Marquee
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 9, vertical: 3.5),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Text(
                              widget.reel['category']!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Row(
                              children: [
                                const Icon(Icons.music_note_rounded,
                                    color: Colors.white70, size: 13),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    widget.reel['music']!,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 10.5,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── 6. Right Action Column (Like, Comment, Save, Share) ────
          Positioned(
            bottom: widget.overlayBottomMargin,
            right: 12,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Like Button
                _ReelActionButton(
                  icon: widget.isLiked
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  iconColor:
                      widget.isLiked ? Colors.redAccent : Colors.white,
                  label: widget.isLiked ? '14.9k' : widget.reel['likes']!,
                  onTap: widget.onLikeToggle,
                ),

                const SizedBox(height: 11),

                // Comment Button
                _ReelActionButton(
                  icon: Icons.chat_bubble_outline_rounded,
                  iconColor: Colors.white,
                  label: widget.reel['comments']!,
                  onTap: () => showComingSoonSnackBar(context, 'Comments'),
                ),

                const SizedBox(height: 11),

                // Bookmark / Save Button
                _ReelActionButton(
                  icon: widget.isSaved
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  iconColor: widget.isSaved
                      ? AppColors.credGold
                      : Colors.white,
                  label: widget.isSaved ? 'Saved' : 'Save',
                  onTap: widget.onSaveToggle,
                ),

                const SizedBox(height: 11),

                // Share Button
                _ReelActionButton(
                  icon: Icons.send_rounded,
                  iconColor: Colors.white,
                  label: 'Share',
                  onTap: _shareReel,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _shareReel() {
    final reelTitle = widget.reel['title'] ?? 'Cranes Academy Reel';
    final reelAuthor = widget.reel['author'] ?? 'Cranes Academy';
    final reelCategory = widget.reel['category'] ?? 'Tech';
    
    final shareMessage = '''
🎥 Check out this Tech Reel on Cranes Digital Academy:
"$reelTitle" by $reelAuthor ($reelCategory)

📱 Watch Reel in App:
https://cranesdigitalacademy.com/reels/${widget.reel['id']}

🎥 Video Direct Link:
${widget.videoUrl}

🚀 Download Cranes Digital Academy App:
https://cranesdigitalacademy.com/download
''';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xEE121216),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Share Reel',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              reelTitle,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppColors.primary,
                child: Icon(Icons.share_rounded, color: Colors.white),
              ),
              title: const Text('Share via Apps',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              subtitle: const Text('WhatsApp, Instagram, Telegram, etc.',
                  style: TextStyle(color: Colors.white54, fontSize: 11)),
              onTap: () {
                Navigator.pop(sheetContext);
                Share.share(shareMessage, subject: reelTitle);
              },
            ),
            const Divider(color: Colors.white12),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                child: const Icon(Icons.copy_rounded, color: Colors.white),
              ),
              title: const Text('Copy Reel Link',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              subtitle: Text(
                'https://cranesdigitalacademy.com/reels/${widget.reel['id']}',
                style: const TextStyle(color: Colors.white54, fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () {
                Clipboard.setData(ClipboardData(text: shareMessage));
                Navigator.pop(sheetContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Reel link & App URL copied to clipboard! 📋'),
                    behavior: SnackBarBehavior.floating,
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _ReelActionButton extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;

  const _ReelActionButton({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: const BoxDecoration(
              color: Colors.black45,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 25),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(blurRadius: 4, color: Colors.black87),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
