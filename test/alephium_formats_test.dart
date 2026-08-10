import 'package:test/test.dart';

import 'package:mobilemonitor/utils/alephium_formats.dart';

void main() {
  group('Alephium format helpers', () {
    test('attoToBigInt parses string and number', () {
      expect(attoToBigInt('100'), BigInt.from(100));
      expect(attoToBigInt(42), BigInt.from(42));
      expect(attoToBigInt(null), BigInt.zero);
      expect(attoToBigInt('not-number'), BigInt.zero);
    });

    test('formatAlph renders positive and negative with fixed decimals', () {
      expect(formatAlph(BigInt.parse('1000000000000000000')), '1');
      expect(formatAlph(BigInt.parse('-1000000000000000000')), '-1');
      expect(formatAlph(BigInt.parse('1234567890000000000')), '1.234567');
    });

    test('formatAlph adds thousand grouping on big integer part', () {
      expect(formatAlph(BigInt.parse('1234567890000000000000000')), '1,234,567.89');
    });

    test('formatShortAddress trims to stable prefix-suffix display', () {
      expect(formatShortAddress('1HkqAaFZY'), '1HkqAaFZY');
      expect(
        formatShortAddress('1HkqAaFZYDh2r9K67JoSiwf4ph7f2qZU1trBDu9nC2C3U'),
        '1HkqAa…nC2C3U',
      );
    });

    test('formatShortHex trims long strings consistently', () {
      expect(formatShortHex('tx_1234567890', leadingChars: 3, trailingChars: 2),
          'tx_…90');
      expect(formatShortHex('short'), 'short');
    });

    test('isValidAlephiumAddress validates rough shape', () {
      expect(
        isValidAlephiumAddress('1HkqAaFZYDh2r9K67JoSiwf4ph7f2qZU1trBDu9nC2C3U'),
        isTrue,
      );
      expect(
        isValidAlephiumAddress('invalid-address!!!'),
        isFalse,
      );
      expect(isValidAlephiumAddress('1'), isFalse);
    });
  });
}
