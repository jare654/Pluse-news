// lib/widgets/loading_shimmer.dart

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../config/app_theme.dart';

/// Full-screen shimmer loading skeleton that mimics the [ArticleCard] layout.
/// Renders five placeholder cards while the network request is in-flight.
class NewsLoadingShimmer extends StatelessWidget {
  const NewsLoadingShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppTheme.elevated,
      highlightColor: AppTheme.border,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 16),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 5,
        itemBuilder: (_, index) => const _ShimmerCard(),
      ),
    );
  }
}

/// A single shimmer placeholder card matching the [ArticleCard] structure.
class _ShimmerCard extends StatelessWidget {
  const _ShimmerCard();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.elevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image placeholder
            Container(
              height: 180,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
            ),
            // Content area
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Source chip placeholder
                      Container(
                        width: 70,
                        height: 18,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const Spacer(),
                      // Time placeholder
                      Container(
                        width: 50,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Title line 1
                  _shimmerLine(double.infinity, 18),
                  const SizedBox(height: 6),
                  // Title line 2
                  _shimmerLine(200, 18),
                  const SizedBox(height: 10),
                  // Description line 1
                  _shimmerLine(double.infinity, 14),
                  const SizedBox(height: 5),
                  // Description line 2
                  _shimmerLine(160, 14),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _shimmerLine(double width, double height) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
        ),
      );
}

/// Generic shimmer box for use in other contexts (e.g. image placeholders).
class ShimmerBox extends StatelessWidget {
  final double? width;
  final double height;
  final double borderRadius;

  const ShimmerBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = 4,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppTheme.elevated,
      highlightColor: AppTheme.border,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppTheme.elevated,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

/// Horizontal shimmer strip — for small inline placeholders.
class ShimmerLine extends StatelessWidget {
  final double width;
  final double height;

  const ShimmerLine({super.key, required this.width, this.height = 14});

  @override
  Widget build(BuildContext context) => ShimmerBox(
        width: width,
        height: height,
      );
}
