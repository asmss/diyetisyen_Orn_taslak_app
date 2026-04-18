import 'package:intl/intl.dart';

class DateFormatter {
  const DateFormatter._();

  static final DateFormat shortDay = DateFormat('d MMM', 'tr_TR');
  static final DateFormat hourMinute = DateFormat('HH:mm', 'tr_TR');
  static final DateFormat full = DateFormat('d MMMM y, HH:mm', 'tr_TR');
}
