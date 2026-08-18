import 'dart:math' as math;
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CDA GRADIENT GLOW FOOTER — Ruixen-inspired Gradient Footer
// Ultra-smooth, high performance rainbow glow footer
// ─────────────────────────────────────────────────────────────────────────────

const _kGlowStops = [
  Color(0xFF340B05), // deep ember floor
  Color(0xFF0358F7), // electric blue
  Color(0xFF5092C7), // steel blue
  Color(0xFF818CF8), // soft indigo (CDA brand)
  Color(0xFFE1ECFE), // near-white shimmer
  Color(0xFFF59E0B), // gold (CDA coins)
  Color(0xFFFA3D1D), // red-orange
  Color(0xFFFD02F5), // magenta
];

class CDAGradientFooter extends StatefulWidget {
  final ScrollController scrollController;
  final double glowHeight;
  final double minReveal;
  final int bars;
  final Widget? child;

  const CDAGradientFooter({
    super.key,
    required this.scrollController,
    this.glowHeight = 200,
    this.minReveal = 0.04,
    this.bars = 9,
    this.child,
  });

  @override
  State<CDAGradientFooter> createState() => _CDAGradientFooterState();
}

class _CDAGradientFooterState extends State<CDAGradientFooter> {
  double _progress = 0.04;

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    final sc = widget.scrollController;
    if (!sc.hasClients) return;
    final maxScroll = sc.position.maxScrollExtent;
    final current  = sc.position.pixels;
    if (maxScroll <= 0) return;

    final remaining = maxScroll - current;
    final h = widget.glowHeight;
    final t = ((h - remaining) / h).clamp(0.0, 1.0);
    final progress = widget.minReveal + (1 - widget.minReveal) * t;

    if ((progress - _progress).abs() > 0.002) {
      setState(() => _progress = progress);
    }
  }

  List<double> _bellHeights(int n, double peakFraction, double valley) {
    final mid = (n - 1) / 2.0;
    return List.generate(n, (i) {
      final t = mid == 0 ? 0.0 : (i - mid).abs() / mid;
      final eased = 1.0 - math.pow(t, 1.24);
      return widget.glowHeight * (valley + (1 - valley) * eased) * peakFraction;
    });
  }

  @override
  Widget build(BuildContext context) {
    final heights = _bellHeights(widget.bars, 0.95, 0.5);

    return ClipRect(
      child: SizedBox(
        height: widget.glowHeight,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
          // Rainbow glow bars
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: widget.glowHeight * _progress,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(widget.bars, (i) {
                return Expanded(
                  child: Container(
                    height: heights[i],
                    margin: const EdgeInsets.symmetric(horizontal: 1.5),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: _kGlowStops,
                        stops: List.generate(
                          _kGlowStops.length,
                          (idx) => idx / (_kGlowStops.length - 1),
                        ),
                      ),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      boxShadow: [
                        BoxShadow(
                          color: _kGlowStops[3].withValues(alpha: 0.35),
                          blurRadius: 18,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),

          // Content overlay (copyright / status)
          if (widget.child != null)
            Positioned.fill(child: widget.child!),
        ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CDA HOME FOOTER CONTENT
// ─────────────────────────────────────────────────────────────────────────────
class CDAHomeFooter extends StatelessWidget {
  const CDAHomeFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8);
    final textSub   = isDark ? const Color(0xFF64748B) : const Color(0xFFB0BAC9);
    final divider   = isDark ? const Color(0xFF1E273A) : const Color(0xFFE8ECF0);

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Divider line
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, divider, Colors.transparent],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Logo + tagline
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F2088), Color(0xFF1E35B3)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F2088).withValues(alpha: 0.35),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: const Icon(Icons.school_rounded, color: Colors.white, size: 14),
              ),
              const SizedBox(width: 8),
              Text(
                'CDA',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          Text(
            'Your career growth partner',
            style: TextStyle(
              fontSize: 10,
              color: textSub,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 10),

          // Links row
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 16,
            runSpacing: 4,
            children: [
              _FooterLink('Privacy', textMuted),
              _FooterLink('Terms', textMuted),
              _FooterLink('Help', textMuted),
              _FooterLink('About', textMuted),
            ],
          ),
          const SizedBox(height: 8),

          // Status + copyright
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 5,
                height: 5,
                decoration: const BoxDecoration(
                  color: Color(0xFF10B981),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                'All systems operational  ·  © 2026 CDA',
                style: TextStyle(
                  fontSize: 9,
                  color: textSub,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  final String label;
  final Color color;
  const _FooterLink(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: color,
        letterSpacing: 0.8,
      ),
    );
  }
}
