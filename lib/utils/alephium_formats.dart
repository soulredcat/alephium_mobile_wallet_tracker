import 'package:intl/intl.dart';

final BigInt _alphUnit = BigInt.from(10).pow(18);

BigInt attoToBigInt(Object? value) {
  if (value == null) {
    return BigInt.zero;
  }

  if (value is num) {
    return BigInt.from(value);
  }

  if (value is String) {
    return BigInt.tryParse(value) ?? BigInt.zero;
  }

  return BigInt.zero;
}

String formatAlph(BigInt amount, {int decimals = 6}) {
  final sign = amount.isNegative ? '-' : '';
  final absAmount = amount.abs();
  final whole = absAmount ~/ _alphUnit;
  final fraction = (absAmount % _alphUnit).toString().padLeft(18, '0');
  final clippedFraction =
      fraction.substring(0, decimals).replaceAll(RegExp(r'0+$'), '');
  final compactFraction = clippedFraction.isEmpty ? '0' : clippedFraction;
  final groupedWhole = _formatWithGroupSeparators(whole.toString());

  if (compactFraction == '0') {
    return '$sign$groupedWhole';
  }
  return '$sign$groupedWhole.$compactFraction';
}

String _formatWithGroupSeparators(String value) {
  if (value.isEmpty || value == '0') {
    return '0';
  }

  final separator = NumberFormat().symbols.GROUP_SEP;
  final bytes = value.codeUnits;
  final buffer = StringBuffer();

  for (var i = 0; i < bytes.length; i++) {
    if (i != 0 && (bytes.length - i) % 3 == 0) {
      buffer.write(separator);
    }
    buffer.writeCharCode(bytes[i]);
  }

  return buffer.toString();
}

String formatShortAddress(String address) {
  if (address.length <= 12) {
    return address;
  }

  return '${address.substring(0, 6)}…${address.substring(address.length - 6)}';
}

String formatShortHex(String value,
    {int leadingChars = 8, int trailingChars = 6}) {
  if (value.length <= leadingChars + trailingChars + 1) {
    return value;
  }

  return '${value.substring(0, leadingChars)}…${value.substring(
    value.length - trailingChars,
  )}';
}

String formatUsdDate(DateTime time) {
  return DateFormat('dd MMM yyyy, HH:mm').format(time.toLocal());
}

String formatRelativeTime(DateTime time) {
  final duration = DateTime.now().difference(time);
  if (duration.inSeconds < 60) {
    return '${duration.inSeconds}s ago';
  }
  if (duration.inMinutes < 60) {
    return '${duration.inMinutes}m ago';
  }
  if (duration.inHours < 24) {
    return '${duration.inHours}h ago';
  }
  if (duration.inDays < 7) {
    return '${duration.inDays}d ago';
  }

  return formatUsdDate(time);
}

bool isValidAlephiumAddress(String address) {
  final trimmed = address.trim();
  if (trimmed.length < 20 || trimmed.length > 70) {
    return false;
  }

  // Alephium addresses are Base58-like and typically start with 1.
  final base58 = RegExp(r'^[1-9A-HJ-NP-Za-km-z]+$');
  return base58.hasMatch(trimmed);
}
