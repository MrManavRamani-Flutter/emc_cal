import 'dart:math' as math;

/// Utility class providing bulletproof boundary and range checks
/// to prevent [RangeError], index out of bounds, and pagination slice failures.
class SafeRangeUtils {
  const SafeRangeUtils._();

  /// Safely extracts a sublist of [list] without throwing [RangeError].
  /// [start] and [end] are clamped to `[0, list.length]`.
  static List<T> safeSublist<T>(List<T> list, int start, [int? end]) {
    if (list.isEmpty) return <T>[];
    final safeStart = start.clamp(0, list.length);
    final targetEnd = end ?? list.length;
    final safeEnd = targetEnd.clamp(safeStart, list.length);
    return list.sublist(safeStart, safeEnd);
  }

  /// Safely gets the element at [index] or returns [fallback] if out of bounds.
  static T? safeGet<T>(List<T> list, int index, {T? fallback}) {
    if (index < 0 || index >= list.length) return fallback;
    return list[index];
  }

  /// Safely gets the first element or returns [fallback] if empty.
  static T? safeFirst<T>(Iterable<T> iterable, {T? fallback}) {
    if (iterable.isEmpty) return fallback;
    return iterable.first;
  }

  /// Safely gets the last element or returns [fallback] if empty.
  static T? safeLast<T>(Iterable<T> iterable, {T? fallback}) {
    if (iterable.isEmpty) return fallback;
    return iterable.last;
  }

  /// Safely slices a string without throwing [RangeError].
  static String safeSubstring(String str, int start, [int? end]) {
    if (str.isEmpty) return '';
    final safeStart = start.clamp(0, str.length);
    final targetEnd = end ?? str.length;
    final safeEnd = targetEnd.clamp(safeStart, str.length);
    return str.substring(safeStart, safeEnd);
  }

  /// Safely clamps a number within [min] and [max].
  static double safeClampDouble(double value, double min, double max) {
    if (value.isNaN || value.isInfinite) return min;
    final effectiveMin = math.min(min, max);
    final effectiveMax = math.max(min, max);
    return value.clamp(effectiveMin, effectiveMax);
  }

  /// Safely clamps a page number between 1 and totalPages
  static int safePage(int page, int totalPages) {
    if (totalPages <= 1) return 1;
    return page.clamp(1, totalPages).toInt();
  }

  /// Calculates a safe page slice for pagination tables (1-based page).
  /// If [page] exceeds total pages, it auto-clamps safely.
  static List<T> safePageSlice<T>(List<T> list, int page1Based, int pageSize) {
    if (list.isEmpty || pageSize <= 0) return <T>[];
    final totalPages = ((list.length - 1) ~/ pageSize) + 1;
    final safeP = page1Based.clamp(1, totalPages).toInt();
    final start = (safeP - 1) * pageSize;
    final end = math.min(start + pageSize, list.length);
    return safeSublist(list, start, end);
  }
}
