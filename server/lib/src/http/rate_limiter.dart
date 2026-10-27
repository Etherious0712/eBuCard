// Limits how often one address can call sensitive endpoints (sign-in,
// registration, password reset), to slow down password guessing and spam.
//
// Counts are kept in memory per server instance. With several Cloud Run
// instances the effective limit is higher; a shared store (e.g. Redis) can
// replace this later if needed.

import 'package:ebucard_server/src/http/api_error.dart';

/// Allows at most [limit] calls per [window] for each key.
class RateLimiter {
  /// Creates a limiter. [now] can be replaced in tests.
  RateLimiter({
    required this.limit,
    required this.window,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  /// Calls allowed per window.
  final int limit;

  /// Length of the window.
  final Duration window;

  final DateTime Function() _now;
  final _hits = <String, List<DateTime>>{};

  /// Records a call for [key]; throws a 429 if the limit is exceeded.
  void hit(String key) {
    final now = _now();
    final cutoff = now.subtract(window);
    final hits = (_hits[key] ?? [])..removeWhere((t) => t.isBefore(cutoff));
    if (hits.length >= limit) {
      _hits[key] = hits;
      throw const ApiException.tooManyRequests();
    }
    _hits[key] = hits..add(now);
    if (_hits.length > 10000) _forgetOld(cutoff);
  }

  /// Drops keys with no recent calls so memory stays bounded.
  void _forgetOld(DateTime cutoff) =>
      _hits.removeWhere((_, hits) => hits.every((t) => t.isBefore(cutoff)));
}
