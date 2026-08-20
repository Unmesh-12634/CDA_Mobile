import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/app_update_service.dart';
import '../../../../core/utils/app_haptics.dart';

class _ReleaseBullet {
  final String title;
  final String? description;
  final String emoji;

  const _ReleaseBullet({
    required this.title,
    this.description,
    this.emoji = '✨',
  });
}

List<_ReleaseBullet> _parseReleaseNotes(String raw) {
  if (raw.trim().isEmpty) {
    return const [
      _ReleaseBullet(
        title: 'Performance & Stability Improvements',
        description: 'Under-the-hood speed optimizations and enhanced response times.',
        emoji: '⚡',
      ),
      _ReleaseBullet(
        title: 'Cloud Data Synchronization',
        description: 'Enhanced profile, resume, and interview reliability.',
        emoji: '☁️',
      ),
    ];
  }

  final lines = raw.split('\n');
  final List<_ReleaseBullet> items = [];

  for (final line in lines) {
    var trimmed = line.trim();
    if (trimmed.isEmpty) continue;
    // Skip top markdown headers
    if (trimmed.startsWith('#') || trimmed.toLowerCase().startsWith('what\'s new') || trimmed.toLowerCase().contains('updates:')) {
      continue;
    }

    // Strip leading list bullets (- , * , 1. )
    trimmed = trimmed.replaceFirst(RegExp(r'^[-*•\d.]+\s*'), '');
    if (trimmed.isEmpty) continue;

    // Detect leading emoji
    String foundEmoji = '✨';
    final emojiRegex = RegExp(r'^(\p{Extended_Pictographic}|\u200D)+', unicode: true);
    final match = emojiRegex.firstMatch(trimmed);
    if (match != null) {
      foundEmoji = match.group(0) ?? '✨';
      trimmed = trimmed.substring(match.end).trim();
    }

    // Parse **Title**: Description or **Title** - Description
    String title = trimmed;
    String? desc;

    if (trimmed.contains('**')) {
      final boldRegex = RegExp(r'\*\*([^*]+)\*\*(?::|-)?\s*(.*)');
      final boldMatch = boldRegex.firstMatch(trimmed);
      if (boldMatch != null) {
        title = boldMatch.group(1)?.trim() ?? '';
        desc = boldMatch.group(2)?.trim();
        if (desc != null && desc.isEmpty) desc = null;
      }
    } else if (trimmed.contains(': ')) {
      final parts = trimmed.split(': ');
      title = parts.first.trim();
      desc = parts.sublist(1).join(': ').trim();
    }

    // Clean remaining markdown
    title = title.replaceAll('*', '').replaceAll('`', '').replaceAll('#', '').trim();
    if (desc != null) {
      desc = desc.replaceAll('*', '').replaceAll('`', '').replaceAll('#', '').trim();
    }

    if (title.isNotEmpty && !items.any((i) => i.title.toLowerCase() == title.toLowerCase())) {
      items.add(_ReleaseBullet(
        title: title,
        description: desc,
        emoji: foundEmoji,
      ));
    }
  }

  if (items.isEmpty) {
    items.add(const _ReleaseBullet(
      title: 'Latest Feature Upgrades & Bug Fixes',
      description: 'Smoother performance, updated security, and cloud sync.',
      emoji: '🚀',
    ));
  }

  return items;
}

class UpdatePromptDialog extends ConsumerWidget {
  final AppUpdateInfo updateInfo;

  const UpdatePromptDialog({super.key, required this.updateInfo});

  static Future<void> show(BuildContext context, AppUpdateInfo info) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => UpdatePromptDialog(updateInfo: info),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final updateState = ref.watch(appUpdateProvider);
    final isDownloading = updateState.status == UpdateStatus.downloading;
    final progress = updateState.downloadProgress;
    final releaseBullets = _parseReleaseNotes(updateInfo.releaseNotes);

    const cranesNavy = Color(0xFF0F2088);
    const cranesCyan = Color(0xFF0284C7);

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 20,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Rocket Icon + Version Chip
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [cranesNavy, cranesCyan],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: cranesNavy.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'New Update Available',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.3,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: isDark
                              ? cranesCyan.withValues(alpha: 0.15)
                              : cranesNavy.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isDark
                                ? cranesCyan.withValues(alpha: 0.3)
                                : cranesNavy.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'v${updateInfo.currentVersion}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 4),
                              child: Icon(Icons.arrow_forward_rounded, size: 11, color: cranesCyan),
                            ),
                            Text(
                              'v${updateInfo.latestVersion}',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: isDark ? const Color(0xFF38BDF8) : cranesNavy,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Section Label
            Text(
              "WHAT'S NEW",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 8),

            // Formatted Scrollable Release Notes Card
            Container(
              constraints: const BoxConstraints(maxHeight: 180),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
              child: RawScrollbar(
                thumbColor: isDark ? Colors.white24 : Colors.black26,
                radius: const Radius.circular(10),
                thickness: 4,
                thumbVisibility: false,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: releaseBullets.map((bullet) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              bullet.emoji,
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    bullet.title,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                                      height: 1.25,
                                    ),
                                  ),
                                  if (bullet.description != null && bullet.description!.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      bullet.description!,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                        height: 1.3,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Download Progress Bar (When Downloading)
            if (isDownloading) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Downloading Update...',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: cranesCyan,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: LinearProgressIndicator(
                  value: progress > 0.0 ? progress : null,
                  minHeight: 8,
                  backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  valueColor: const AlwaysStoppedAnimation<Color>(cranesCyan),
                ),
              ),
              const SizedBox(height: 14),
            ],

            if (updateState.errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  updateState.errorMessage!,
                  style: const TextStyle(fontSize: 11, color: Colors.redAccent),
                ),
              ),

            // Action Buttons
            Row(
              children: [
                if (!isDownloading)
                  Expanded(
                    flex: 1,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        side: BorderSide(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        'Later',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ),
                if (!isDownloading) const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [cranesNavy, cranesCyan],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: cranesNavy.withValues(alpha: 0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: isDownloading
                          ? null
                          : () async {
                              AppHaptics.heavyImpact();
                              await ref.read(appUpdateProvider.notifier).downloadAndInstall();
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isDownloading ? Icons.hourglass_top_rounded : Icons.download_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isDownloading ? 'Installing...' : 'Update Now',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13.5,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
