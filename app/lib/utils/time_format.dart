/// The API sends UTC times as "yyyy-MM-dd HH:mm:ss".
DateTime? parseApiDate(String? value) {
  if (value == null || value.isEmpty) {
    return null;
  }
  return DateTime.tryParse('${value.replaceFirst(' ', 'T')}Z');
}

String timeAgo(DateTime? time, {DateTime? now}) {
  if (time == null) {
    return '';
  }

  final difference = (now ?? DateTime.now()).difference(time);
  if (difference.inMinutes < 1) {
    return 'just now';
  }
  if (difference.inMinutes < 60) {
    return '${difference.inMinutes} min ago';
  }
  if (difference.inHours < 24) {
    return _plural(difference.inHours, 'hour');
  }
  return _plural(difference.inDays, 'day');
}

String _plural(int count, String unit) {
  return '$count $unit${count == 1 ? '' : 's'} ago';
}
