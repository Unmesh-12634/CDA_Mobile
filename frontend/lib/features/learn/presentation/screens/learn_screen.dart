import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/storage/local_cache_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/supabase_config.dart';

import '../../../../core/network/java_api_service.dart';
import '../../../auth/data/auth_provider.dart';
import '../../../profile/data/user_profile_provider.dart';
import '../../../home/data/weekly_goal_provider.dart';
import '../../data/reels_repository.dart';
import '../../data/saved_reels_provider.dart';

// ─────────────────────────────────────────────────────────────
// VIDEO CONTROLLER PRELOAD MANAGER (Zero Buffering / Instant Play)
// ─────────────────────────────────────────────────────────────
class ReelVideoPreloadManager {
  static final ReelVideoPreloadManager instance = ReelVideoPreloadManager._();
  ReelVideoPreloadManager._();

  final Map<String, VideoPlayerController> _cache = {};

  Future<VideoPlayerController> getOrCreateController(String videoUrl) async {
    if (_cache.containsKey(videoUrl)) {
      final ctrl = _cache[videoUrl]!;
      if (ctrl.value.isInitialized) {
        return ctrl;
      }
    }

    final ctrl = VideoPlayerController.networkUrl(
      Uri.parse(videoUrl),
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );
    _cache[videoUrl] = ctrl;

    try {
      await ctrl.initialize();
      await ctrl.setLooping(true);
    } catch (e) {
      debugPrint('Preload error for $videoUrl: $e');
    }
    return ctrl;
  }

  void preloadNext(List<String> urls, int currentIndex) {
    if (currentIndex + 1 < urls.length) {
      final nextUrl = urls[currentIndex + 1];
      if (!_cache.containsKey(nextUrl)) {
        getOrCreateController(nextUrl);
      }
    }
  }

  void pauseAll() {
    _cache.forEach((_, ctrl) {
      try {
        if (ctrl.value.isInitialized && ctrl.value.isPlaying) {
          ctrl.pause();
        }
      } catch (_) {}
    });
  }

  void disposeOldExcept(List<String> keepUrls) {
    final keepSet = keepUrls.toSet();
    final keysToRemove = <String>[];
    _cache.forEach((url, ctrl) {
      if (!keepSet.contains(url)) {
        ctrl.dispose();
        keysToRemove.add(url);
      }
    });
    for (final k in keysToRemove) {
      _cache.remove(k);
    }
  }
}

// ─────────────────────────────────────────────────────────────
// LEARN SCREEN — Live Database Reels & Zero-Buffering Feed
// ─────────────────────────────────────────────────────────────
class LearnScreen extends ConsumerStatefulWidget {
  const LearnScreen({super.key});

  @override
  ConsumerState<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends ConsumerState<LearnScreen> with WidgetsBindingObserver {
  late final PageController _pageController;
  int _currentPageIndex = 0;
  String _selectedCategory = 'All Topics';
  bool _isSwiping = false;

  final Map<String, bool> _likedMap = {};
  final Map<String, int> _likeCountMap = {};
  final Map<String, bool> _savedMap = {};
  final Map<String, int> _commentCountMap = {};
  final Map<String, bool> _followingMap = {};

  final List<String> _categories = [
    'All Topics',
    'Java',
    'Flutter',
    'Python',
    'System Design',
    'AI/ML',
    'PostgreSQL',
    'DevOps',
  ];

  RealtimeChannel? _reelsRealtimeChannel;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    WidgetsBinding.instance.addObserver(this);
    _loadUserSavedAndLikedReels();
    _setupRealtimeSubscription();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      ReelVideoPreloadManager.instance.pauseAll();
    }
  }

  @override
  void deactivate() {
    ReelVideoPreloadManager.instance.pauseAll();
    super.deactivate();
  }

  void _setupRealtimeSubscription() {
    try {
      _reelsRealtimeChannel = SupabaseConfig.client
          .channel('public:reels_realtime_feed')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'reels',
            callback: (payload) {
              final newRecord = payload.newRecord;
              if (newRecord.isNotEmpty && mounted) {
                final rId = newRecord['id']?.toString();
                final likes = (newRecord['likes_count'] as num?)?.toInt();
                final comments = (newRecord['comments_count'] as num?)?.toInt();
                if (rId != null) {
                  setState(() {
                    if (likes != null) _likeCountMap[rId] = likes;
                    if (comments != null) _commentCountMap[rId] = comments;
                  });
                }
              }
            },
          )
          .subscribe();
    } catch (e) {
      debugPrint('Realtime channel notice: $e');
    }
  }

  Future<void> _loadUserSavedAndLikedReels() async {
    final profile = ref.read(userProfileProvider);
    final userEmail = profile.email.isNotEmpty ? profile.email : ref.read(authProvider).email;

    try {
      final savedRes = await SupabaseConfig.client
          .from('saved_reels')
          .select('reel_id');
      if (savedRes.isNotEmpty) {
        for (final row in savedRes) {
          final rId = row['reel_id']?.toString();
          if (rId != null) {
            _savedMap[rId] = true;
          }
        }
      }

      final likesRes = await SupabaseConfig.client
          .from('reel_likes')
          .select('reel_id')
          .eq('user_email', userEmail);
      if (likesRes.isNotEmpty) {
        for (final row in likesRes) {
          final rId = row['reel_id']?.toString();
          if (rId != null) {
            _likedMap[rId] = true;
          }
        }
      }
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Reels state load notice: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ReelVideoPreloadManager.instance.pauseAll();
    _reelsRealtimeChannel?.unsubscribe();
    _pageController.dispose();
    super.dispose();
  }

  void _onScrollNotification(ScrollNotification notification, int totalCount) {
    if (notification is ScrollUpdateNotification && !_isSwiping) {
      final delta = notification.scrollDelta ?? 0;
      if (delta.abs() > 16) {
        if (delta > 0 && _currentPageIndex < totalCount - 1) {
          _isSwiping = true;
          _pageController
              .nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.fastOutSlowIn)
              .then((_) => _isSwiping = false);
        } else if (delta < 0 && _currentPageIndex > 0) {
          _isSwiping = true;
          _pageController
              .previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.fastOutSlowIn)
              .then((_) => _isSwiping = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final reelsAsync = ref.watch(allReelsFeedProvider);
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final topInset = MediaQuery.of(context).padding.top;
    final double overlayBottomMargin = 122.0 + (bottomInset > 0 ? 6.0 : 0.0);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── REELS FEED ──
          reelsAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
            error: (err, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.cloud_off_rounded, size: 56, color: Colors.white38),
                    const SizedBox(height: 12),
                    Text(
                      'Failed to load reels from database',
                      style: AppTypography.titleMedium.copyWith(color: Colors.white70),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                      onPressed: () => ref.refresh(allReelsFeedProvider),
                      child: const Text('Retry', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ),
            data: (allReels) {
              final filtered = allReels.where((reel) {
                if (_selectedCategory == 'All Topics') return true;
                return reel.category.toLowerCase().contains(_selectedCategory.toLowerCase()) ||
                    reel.title.toLowerCase().contains(_selectedCategory.toLowerCase()) ||
                    reel.tags.any((t) => t.toLowerCase().contains(_selectedCategory.toLowerCase()));
              }).toList();

              if (filtered.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.video_library_outlined, size: 64, color: Colors.white38),
                        const SizedBox(height: 16),
                        Text(
                          'No reels in $_selectedCategory',
                          textAlign: TextAlign.center,
                          style: AppTypography.titleMedium.copyWith(color: Colors.white70),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => setState(() => _selectedCategory = 'All Topics'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Reset Filters'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Trigger preloading of next videos in the feed
              final videoUrls = filtered.map((r) => r.videoUrl).toList();
              ReelVideoPreloadManager.instance.preloadNext(videoUrls, _currentPageIndex);

              return NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  _onScrollNotification(notification, filtered.length);
                  return false;
                },
                child: PageView.builder(
                  key: const PageStorageKey('reels_feed_main_pv'),
                  controller: _pageController,
                  physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                  scrollDirection: Axis.vertical,
                  itemCount: filtered.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPageIndex = index;
                    });
                    ReelVideoPreloadManager.instance.preloadNext(videoUrls, index);
                    // Mark today's learning mission active for studying video content
                    ref.read(weeklyGoalProvider.notifier).completeToday();
                  },
                  itemBuilder: (context, index) {
                    final reel = filtered[index];
                    final isLiked = _likedMap[reel.id] ?? false;
                    final currentLikes = _likeCountMap[reel.id] ?? reel.likesCount;
                    final isSaved = _savedMap[reel.id] ?? false;
                    final currentComments = _commentCountMap[reel.id] ?? reel.commentsCount;
                    final isFollowing = _followingMap[reel.id] ?? false;
                    final isCurrentPage = index == _currentPageIndex;

                    return AnimatedBuilder(
                      animation: _pageController,
                      builder: (context, child) {
                        double pageOffset = 0.0;
                        if (_pageController.hasClients &&
                            _pageController.positions.length == 1 &&
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
                      child: _ReelItemView(
                        reel: reel,
                        isCurrentPage: isCurrentPage,
                        isLiked: isLiked,
                        likesCount: currentLikes,
                        isSaved: isSaved,
                        commentsCount: currentComments,
                        isFollowing: isFollowing,
                        overlayBottomMargin: overlayBottomMargin,
                        onLikeToggle: () => _handleLikeToggle(reel),
                        onSaveToggle: () => _handleSaveToggle(reel),
                        onFollowToggle: () => _handleFollowToggle(reel),
                        onCommentsTap: () => _showCommentsSheet(context, reel),
                      ),
                    );
                  },
                ),
              );
            },
          ),

          // ── TOP HEADER BAR ──
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
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
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
                              setState(() {
                                _selectedCategory = cat;
                                _currentPageIndex = 0;
                              });
                              if (_pageController.hasClients && _pageController.positions.length == 1) {
                                _pageController.jumpToPage(0);
                              }
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



  // ── REAL ACTIONS ──

  Future<void> _handleLikeToggle(ReelModel reel) async {
    final profile = ref.read(userProfileProvider);
    final userEmail = profile.email.isNotEmpty ? profile.email : ref.read(authProvider).email;
    final isCurrentlyLiked = _likedMap[reel.id] ?? false;
    final currentLikes = _likeCountMap[reel.id] ?? reel.likesCount;
    final nextLiked = !isCurrentlyLiked;
    final nextCount = nextLiked ? currentLikes + 1 : (currentLikes > 0 ? currentLikes - 1 : 0);

    setState(() {
      _likedMap[reel.id] = nextLiked;
      _likeCountMap[reel.id] = nextCount;
    });

    LocalCacheService().saveLikedReel(reel.id, nextLiked);
    
    // 1. Sync to Java Backend
    JavaApiService.toggleReelLike(reelId: reel.id, email: userEmail);

    // 2. Sync to Supabase Database
    final repo = ref.read(reelsRepositoryProvider);
    await repo.toggleLike(reel.id, userEmail);
  }

  Future<void> _handleSaveToggle(ReelModel reel) async {
    final isCurrentlySaved = _savedMap[reel.id] ?? false;
    final newSaved = !isCurrentlySaved;

    setState(() {
      _savedMap[reel.id] = newSaved;
    });

    LocalCacheService().saveBookmarkedReel(reel.id, newSaved);
    await ref.read(savedReelsProvider.notifier).toggleSave(reel.id);

    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(newSaved ? 'Reel saved to DB Bookmarks 🔖' : 'Removed from Bookmarks'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _handleFollowToggle(ReelModel reel) {
    final isFollowing = _followingMap[reel.id] ?? false;
    setState(() => _followingMap[reel.id] = !isFollowing);
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(!isFollowing ? 'Following ${reel.authorName}' : 'Unfollowed ${reel.authorName}'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showCommentsSheet(BuildContext context, ReelModel reel) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _ReelCommentsBottomSheet(
        reel: reel,
        onCommentAdded: () {
          final count = _commentCountMap[reel.id] ?? reel.commentsCount;
          setState(() {
            _commentCountMap[reel.id] = count + 1;
          });
        },
        onCommentDeleted: () {
          final count = _commentCountMap[reel.id] ?? reel.commentsCount;
          setState(() {
            _commentCountMap[reel.id] = (count > 0) ? count - 1 : 0;
          });
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// REEL ITEM VIEW WITH INSTANT PLAYBACK & ZERO BUFFERING
// ─────────────────────────────────────────────────────────────
class _ReelItemView extends StatefulWidget {
  final ReelModel reel;
  final bool isCurrentPage;
  final bool isLiked;
  final int likesCount;
  final bool isSaved;
  final int commentsCount;
  final bool isFollowing;
  final double overlayBottomMargin;
  final VoidCallback onLikeToggle;
  final VoidCallback onSaveToggle;
  final VoidCallback onFollowToggle;
  final VoidCallback onCommentsTap;

  const _ReelItemView({
    required this.reel,
    required this.isCurrentPage,
    required this.isLiked,
    required this.likesCount,
    required this.isSaved,
    required this.commentsCount,
    required this.isFollowing,
    required this.overlayBottomMargin,
    required this.onLikeToggle,
    required this.onSaveToggle,
    required this.onFollowToggle,
    required this.onCommentsTap,
  });

  @override
  State<_ReelItemView> createState() => _ReelItemViewState();
}

class _ReelItemViewState extends State<_ReelItemView> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _showPlayPauseIndicator = false;

  bool _showHeartAnimation = false;
  Offset _heartPos = Offset.zero;

  @override
  void initState() {
    super.initState();
    _loadVideo();
  }

  Future<void> _loadVideo() async {
    final ctrl = await ReelVideoPreloadManager.instance.getOrCreateController(widget.reel.videoUrl);
    if (!mounted) return;
    setState(() {
      _controller = ctrl;
      _isInitialized = ctrl.value.isInitialized;
    });

    if (widget.isCurrentPage && _isInitialized) {
      ctrl.play();
      setState(() => _isPlaying = true);
    }
  }

  @override
  void didUpdateWidget(covariant _ReelItemView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_controller != null && _isInitialized) {
      if (widget.isCurrentPage && !_controller!.value.isPlaying) {
        _controller!.play();
        setState(() => _isPlaying = true);
      } else if (!widget.isCurrentPage && _controller!.value.isPlaying) {
        _controller!.pause();
        setState(() => _isPlaying = false);
      }
    }
  }

  void _togglePlayPause() {
    if (_controller == null || !_isInitialized) return;
    setState(() {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
        _isPlaying = false;
      } else {
        _controller!.play();
        _isPlaying = true;
      }
      _showPlayPauseIndicator = true;
    });

    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) setState(() => _showPlayPauseIndicator = false);
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
      if (mounted) setState(() => _showHeartAnimation = false);
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
          // ── 1. Video Player ──
          if (_isInitialized && _controller != null)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller!.value.size.width > 0 ? _controller!.value.size.width : size.width,
                  height: _controller!.value.size.height > 0 ? _controller!.value.size.height : size.height,
                  child: VideoPlayer(_controller!),
                ),
              ),
            )
          else
            Container(
              color: const Color(0xFF0F172A),
              child: const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 2.5,
                ),
              ),
            ),

          // ── 2. Gradient Scrim ──
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

          // ── 3. Play / Pause Indicator ──
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
                    size: 52,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

          // ── 4. Double Tap Heart Burst ──
          if (_showHeartAnimation)
            Positioned(
              left: _heartPos.dx - 45,
              top: _heartPos.dy - 45,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.2, end: 1.2),
                duration: const Duration(milliseconds: 400),
                curve: Curves.elasticOut,
                builder: _heartScaleBuilder,
                child: const Icon(Icons.favorite_rounded, color: Colors.redAccent, size: 90),
              ),
            ),

          // ── 5. Left Info Glass Container ──
          Positioned(
            left: 12,
            right: 76,
            bottom: widget.overlayBottomMargin,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0x77000000),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.18),
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
                      // Author Row
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: AppColors.primary,
                            child: Text(
                              widget.reel.authorName.isNotEmpty ? widget.reel.authorName[0] : 'C',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.reel.authorName,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.5),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  widget.reel.category,
                                  style: const TextStyle(color: Colors.white70, fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: widget.onFollowToggle,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: widget.isFollowing ? Colors.white24 : AppColors.primary,
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Text(
                                widget.isFollowing ? 'Following' : 'Follow',
                                style: TextStyle(
                                  color: widget.isFollowing ? Colors.white : Colors.white,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Reel Title
                      Text(
                        widget.reel.title,
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

                      // Skill Badge & Audio
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Text(
                              widget.reel.category,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Row(
                              children: [
                                Icon(Icons.music_note_rounded, color: Colors.white70, size: 13),
                                SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    'Cranes Digital Academy · Masterclass Audio',
                                    style: TextStyle(color: Colors.white70, fontSize: 10.5),
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

          // ── 6. Right Action Column (Like, Comment, Save, Share) ──
          Positioned(
            bottom: widget.overlayBottomMargin,
            right: 12,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Like Button
                _ReelActionButton(
                  icon: widget.isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  iconColor: widget.isLiked ? Colors.redAccent : Colors.white,
                  label: '${widget.likesCount}',
                  onTap: widget.onLikeToggle,
                ),

                const SizedBox(height: 11),

                // Comment Button
                _ReelActionButton(
                  icon: Icons.chat_bubble_outline_rounded,
                  iconColor: Colors.white,
                  label: '${widget.commentsCount}',
                  onTap: widget.onCommentsTap,
                ),

                const SizedBox(height: 11),

                // Bookmark / Save Button
                _ReelActionButton(
                  icon: widget.isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                  iconColor: widget.isSaved ? AppColors.credGold : Colors.white,
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

  static Widget _heartScaleBuilder(BuildContext context, double value, Widget? child) {
    return Transform.scale(scale: value, child: child);
  }

  void _shareReel() {
    final shareMessage = '''
🎥 Check out this Tech Reel on Cranes Digital Academy:
"${widget.reel.title}" by ${widget.reel.authorName} (${widget.reel.category})

📱 Watch Reel in App:
https://cranesdigitalacademy.com/reels/${widget.reel.id}

🎥 Video Direct Link:
${widget.reel.videoUrl}

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
              widget.reel.title,
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
              title: const Text('Share via Apps', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              subtitle: const Text('WhatsApp, Instagram, Telegram, etc.', style: TextStyle(color: Colors.white54, fontSize: 11)),
              onTap: () {
                Navigator.pop(sheetContext);
                Share.share(shareMessage, subject: widget.reel.title);
              },
            ),
            const Divider(color: Colors.white12),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                child: const Icon(Icons.copy_rounded, color: Colors.white),
              ),
              title: const Text('Copy Reel Link', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              subtitle: Text(
                'https://cranesdigitalacademy.com/reels/${widget.reel.id}',
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

// ─────────────────────────────────────────────────────────────
// REAL INSTAGRAM-STYLE COMMENTS BOTTOM SHEET
// ─────────────────────────────────────────────────────────────
class _ReelCommentsBottomSheet extends ConsumerStatefulWidget {
  final ReelModel reel;
  final VoidCallback onCommentAdded;
  final VoidCallback? onCommentDeleted;

  const _ReelCommentsBottomSheet({
    required this.reel,
    required this.onCommentAdded,
    this.onCommentDeleted,
  });

  @override
  ConsumerState<_ReelCommentsBottomSheet> createState() => _ReelCommentsBottomSheetState();
}

class _ReelCommentsBottomSheetState extends ConsumerState<_ReelCommentsBottomSheet> {
  final TextEditingController _commentCtrl = TextEditingController();
  List<ReelCommentModel> _comments = [];
  bool _isLoading = true;
  bool _isPosting = false;
  String? _deletingCommentId;

  @override
  void initState() {
    super.initState();
    _fetchComments();
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchComments() async {
    final repo = ref.read(reelsRepositoryProvider);
    final list = await repo.fetchComments(widget.reel.id);
    if (mounted) {
      setState(() {
        _comments = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _postComment() async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty || _isPosting) return;

    final profile = ref.read(userProfileProvider);
    final userEmail = profile.email.isNotEmpty ? profile.email : ref.read(authProvider).email;
    final userName = profile.name.isNotEmpty ? profile.name : (ref.read(authProvider).fullName.isNotEmpty ? ref.read(authProvider).fullName : 'Learner');

    setState(() => _isPosting = true);

    final repo = ref.read(reelsRepositoryProvider);
    final newComment = await repo.postComment(
      reelId: widget.reel.id,
      userEmail: userEmail,
      userName: userName,
      userAvatar: profile.avatarImagePath,
      comment: text,
    );

    if (mounted) {
      if (newComment != null) {
        setState(() {
          _comments.insert(0, newComment);
          _commentCtrl.clear();
          _isPosting = false;
        });
        widget.onCommentAdded();
      } else {
        setState(() => _isPosting = false);
      }
    }
  }

  Future<void> _deleteComment(ReelCommentModel comment) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Delete Comment', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        content: const Text(
          'Are you sure you want to delete this comment? This action cannot be undone.',
          style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFEF4444)),
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _deletingCommentId = comment.id);

    final repo = ref.read(reelsRepositoryProvider);
    final success = await repo.deleteComment(
      commentId: comment.id,
      reelId: widget.reel.id,
    );

    if (mounted) {
      setState(() => _deletingCommentId = null);
      if (success) {
        setState(() {
          _comments.removeWhere((c) => c.id == comment.id);
        });
        widget.onCommentDeleted?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Comment deleted'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  static const List<String> _quickEmojis = ['❤️', '🔥', '👏', '💡', '🚀', '💯', '🙌', '✨'];

  void _insertEmoji(String emoji) {
    final text = _commentCtrl.text;
    final selection = _commentCtrl.selection;
    if (selection.start >= 0) {
      final newText = text.replaceRange(selection.start, selection.end, emoji);
      _commentCtrl.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: selection.start + emoji.length),
      );
    } else {
      _commentCtrl.text = '$text$emoji';
      _commentCtrl.selection = TextSelection.collapsed(offset: _commentCtrl.text.length);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomInset = mediaQuery.viewInsets.bottom;
    final bottomPadding = mediaQuery.padding.bottom;
    final profile = ref.watch(userProfileProvider);
    final authState = ref.watch(authProvider);
    final currentEmail = profile.email.isNotEmpty ? profile.email : authState.email;
    final currentName = profile.name.isNotEmpty ? profile.name : (authState.fullName.isNotEmpty ? authState.fullName : 'Learner');

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        height: mediaQuery.size.height * 0.72,
        decoration: const BoxDecoration(
          color: Color(0xFF0F172A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(color: Colors.black54, blurRadius: 20, spreadRadius: 5),
          ],
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 44,
                height: 4.5,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Comments',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_comments.length}',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 22),
                    splashRadius: 20,
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white12, height: 1),

            // Comments List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : _comments.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.05),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.chat_bubble_outline_rounded, size: 36, color: Colors.white38),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'No comments yet',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14.5),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Be the first to share your thoughts!',
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12.5),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          itemCount: _comments.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 16),
                          itemBuilder: (context, i) {
                            final c = _comments[i];
                            final isMyComment = (c.userEmail.isNotEmpty && c.userEmail == currentEmail) ||
                                (c.userName == currentName && currentName != 'Learner');
                            final isDeletingThis = _deletingCommentId == c.id;

                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Avatar
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
                                    ),
                                  ),
                                  child: ClipOval(
                                    child: (c.userAvatar != null && c.userAvatar!.isNotEmpty)
                                        ? Image.network(
                                            c.userAvatar!,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => Center(
                                              child: Text(
                                                c.userName.isNotEmpty ? c.userName[0].toUpperCase() : 'U',
                                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                              ),
                                            ),
                                          )
                                        : Center(
                                            child: Text(
                                              c.userName.isNotEmpty ? c.userName[0].toUpperCase() : 'U',
                                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // Comment Content
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            c.userName,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                          if (isMyComment) ...[
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                              decoration: BoxDecoration(
                                                color: AppColors.primary.withValues(alpha: 0.2),
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(color: AppColors.primary.withValues(alpha: 0.4), width: 0.8),
                                              ),
                                              child: const Text(
                                                'You',
                                                style: TextStyle(
                                                  color: AppColors.primary,
                                                  fontSize: 9.5,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                            ),
                                          ],
                                          const SizedBox(width: 8),
                                          Text(
                                            _formatTimeAgo(c.createdAt),
                                            style: TextStyle(
                                              color: Colors.white.withValues(alpha: 0.45),
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        c.comment,
                                        style: const TextStyle(
                                          color: Color(0xFFF8FAFC),
                                          fontSize: 13.5,
                                          height: 1.35,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Actions (Delete if own, else small heart)
                                if (isMyComment)
                                  isDeletingThis
                                      ? const Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Color(0xFFEF4444),
                                            ),
                                          ),
                                        )
                                      : IconButton(
                                          icon: const Icon(
                                            Icons.delete_outline_rounded,
                                            size: 18,
                                            color: Color(0xFFEF4444),
                                          ),
                                          tooltip: 'Delete comment',
                                          splashRadius: 18,
                                          padding: const EdgeInsets.all(4),
                                          constraints: const BoxConstraints(),
                                          onPressed: () => _deleteComment(c),
                                        ),
                              ],
                            );
                          },
                        ),
            ),

            // Quick Emoji Reaction Bar (Instagram-style)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: const BoxDecoration(
                color: Color(0xFF1E293B),
                border: Border(top: BorderSide(color: Colors.white10)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: _quickEmojis.map((emoji) {
                  return InkWell(
                    onTap: () => _insertEmoji(emoji),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      child: Text(
                        emoji,
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            // Comment Input Bar
            Container(
              padding: EdgeInsets.fromLTRB(14, 8, 14, 10 + (bottomInset == 0 ? bottomPadding : 4)),
              decoration: const BoxDecoration(
                color: Color(0xFF1E293B),
              ),
              child: Row(
                children: [
                  // Mini User Avatar
                  Container(
                    width: 32,
                    height: 32,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
                      ),
                    ),
                    child: Center(
                      child: Text(
                        currentName.isNotEmpty ? currentName[0].toUpperCase() : 'U',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ),

                  // Input Box with clear text visibility
                  Expanded(
                    child: Theme(
                      data: ThemeData.dark().copyWith(
                        textSelectionTheme: const TextSelectionThemeData(
                          cursorColor: Color(0xFF38BDF8),
                          selectionColor: Color(0x6638BDF8),
                          selectionHandleColor: Color(0xFF38BDF8),
                        ),
                      ),
                      child: TextField(
                        controller: _commentCtrl,
                        cursorColor: const Color(0xFF38BDF8),
                        cursorWidth: 2.2,
                        cursorRadius: const Radius.circular(2),
                        style: const TextStyle(
                          color: Color(0xFFF8FAFC),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFF0F172A),
                          hintText: 'Add a comment as $currentName...',
                          hintStyle: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: const BorderSide(color: Color(0xFF334155), width: 1.2),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: const BorderSide(color: Color(0xFF334155), width: 1.2),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: const BorderSide(color: Color(0xFF38BDF8), width: 1.5),
                          ),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                        ),
                        onSubmitted: (_) => _postComment(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  _isPosting
                      ? const SizedBox(
                          width: 36,
                          height: 36,
                          child: Padding(
                            padding: EdgeInsets.all(8),
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                          ),
                        )
                      : Container(
                          width: 38,
                          height: 38,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 20),
                            onPressed: _postComment,
                          ),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 45) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

// ─────────────────────────────────────────────────────────────
// REEL ACTION BUTTON WIDGET
// ─────────────────────────────────────────────────────────────
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
