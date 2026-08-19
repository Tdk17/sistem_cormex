import 'package:sistem_cormex/Src/Models/dashboardModels.dart';

String formatCurrency(double value) {
  final negative = value < 0;
  final absolute = value.abs().toStringAsFixed(2);
  final parts = absolute.split('.');
  final digits = parts.first;
  final buffer = StringBuffer();

  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) buffer.write('.');
    buffer.write(digits[index]);
  }

  return '${negative ? '-' : ''}R\$ ${buffer.toString()},${parts.last}';
}

String formatPercent(double? value, {bool showSign = false}) {
  if (value == null) return 'Sem comparação';
  final sign = showSign && value > 0 ? '+' : '';
  return '$sign${value.toStringAsFixed(1).replaceAll('.', ',')}%';
}

String formatReportValue(dynamic value, String type) {
  if (value == null) return '—';
  if (type == 'currency') return formatCurrency(doubleValue(value));
  if (type == 'percent') return formatPercent(doubleValue(value));
  if (type == 'boolean') return boolValue(value) ? 'Sim' : 'Não';
  if (type == 'date' || type == 'datetime') {
    final date = DateTime.tryParse(value.toString());
    if (date == null) return value.toString();
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final base = '$day/$month/${date.year}';
    if (type == 'date') return base;
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$base $hour:$minute';
  }
  return value.toString();
}

String periodLabel(String period) {
  final parts = period.split('-');
  if (parts.length != 2) return period;
  const months = [
    'Janeiro',
    'Fevereiro',
    'Março',
    'Abril',
    'Maio',
    'Junho',
    'Julho',
    'Agosto',
    'Setembro',
    'Outubro',
    'Novembro',
    'Dezembro',
  ];
  final month = int.tryParse(parts[1]);
  if (month == null || month < 1 || month > 12) return period;
  return '${months[month - 1]} de ${parts[0]}';
}
