import 'package:intl/intl.dart';

final _currency = NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp',
  decimalDigits: 0,
);
final _date = DateFormat('d MMMM yyyy', 'en_US');
final _dateTime = DateFormat('d MMM yyyy, HH:mm', 'en_US');
final _time = DateFormat('HH:mm', 'en_US');

String formatCurrency(num value) => _currency.format(value);
String formatDate(DateTime? value) => value == null ? '-' : _date.format(value);
String formatDateTime(DateTime? value) =>
    value == null ? '-' : _dateTime.format(value.toLocal());
String formatTime(DateTime? value) =>
    value == null ? '-' : _time.format(value.toLocal());

String formatDuration(Duration? value) {
  if (value == null) return 'In progress';
  final hours = value.inHours;
  final minutes = value.inMinutes.remainder(60);
  if (hours == 0) return '$minutes min';
  return '${hours}h ${minutes}m';
}

double asDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

DateTime? asDateTime(dynamic value) {
  if (value == null || value.toString().isEmpty) return null;
  return DateTime.tryParse(value.toString());
}
