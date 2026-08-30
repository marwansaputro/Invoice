import 'package:intl/intl.dart';

class AppFormatters {
  AppFormatters._();

  static final NumberFormat _currency = NumberFormat.decimalPattern('id_ID');
  static final DateFormat _date = DateFormat('dd MMM yyyy');
  static final DateFormat _dateInput = DateFormat('dd/MM/yyyy');

  static String money(double value, {String symbol = 'Rp'}) {
    final rounded = value.round();
    return '$symbol${_currency.format(rounded)}';
  }

  static String date(DateTime date) => _date.format(date);
  static String dateInput(DateTime date) => _dateInput.format(date);
}
