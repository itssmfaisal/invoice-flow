/// Small formatting helpers (kept dependency-free on purpose).
abstract final class Fmt {
  static const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  /// `$25,000`, or `$2.45M` / `$340K` when [compact] is true.
  static String money(double value, {bool compact = false}) {
    final negative = value < 0;
    final abs = value.abs();
    String text;
    if (compact && abs >= 1e6) {
      text = '\$${_trimZeros((abs / 1e6).toStringAsFixed(2))}M';
    } else if (compact && abs >= 1e3) {
      text = '\$${_trimZeros((abs / 1e3).toStringAsFixed(1))}K';
    } else {
      text = '\$${_grouped(abs)}';
    }
    return negative ? '-$text' : text;
  }

  static String percent(double fraction, {int digits = 1}) => '${(fraction * 100).toStringAsFixed(digits)}%';

  static String signedPercent(double fraction) => '${fraction >= 0 ? '+' : ''}${(fraction * 100).toStringAsFixed(1)}%';

  static String date(DateTime d) => '${_months[d.month - 1]} ${d.day}, ${d.year}';

  static String shortDate(DateTime d) => '${_months[d.month - 1]} ${d.day}';

  static String month(DateTime d) => _months[d.month - 1];

  static String relative(DateTime d, {DateTime? now}) {
    final diff = (now ?? DateTime.now()).difference(d);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 30) return '${diff.inDays} days ago';
    final months = diff.inDays ~/ 30;
    return months == 1 ? '1 month ago' : '$months months ago';
  }

  static String payoutTime(int hours) {
    if (hours <= 0) return 'Same day';
    if (hours < 48) return 'in $hours hrs';
    return 'in ${hours ~/ 24} days';
  }

  static String _trimZeros(String s) => s.contains('.') ? s.replaceFirst(RegExp(r'\.?0+$'), '') : s;

  static String _grouped(double value) {
    final totalCents = (value * 100).round();
    final whole = (totalCents ~/ 100).toString();
    final cents = totalCents % 100;
    final buffer = StringBuffer();
    for (var i = 0; i < whole.length; i++) {
      if (i > 0 && (whole.length - i) % 3 == 0) buffer.write(',');
      buffer.write(whole[i]);
    }
    if (cents > 0) buffer.write('.${cents.toString().padLeft(2, '0')}');
    return buffer.toString();
  }
}
