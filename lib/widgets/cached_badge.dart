// lib/widgets/cached_badge.dart

import 'package:flutter/material.dart';

import '../config/app_theme.dart';

/// A small pill-shaped badge displayed in the AppBar when the
/// currently visible data was served from the in-memory cache
/// rather than a fresh network request.
///
/// This satisfies the BONUS requirement:
/// "Show a visible 'Cached' badge when data is served from cache."
class CachedBadge extends StatelessWidget {
  const CachedBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.success.withAlpha(25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.success.withAlpha(80),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppTheme.success,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            'CACHED',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppTheme.success,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}
