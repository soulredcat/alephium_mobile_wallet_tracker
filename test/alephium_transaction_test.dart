import 'package:test/test.dart';

import 'package:mobilemonitor/models/alephium_transaction.dart';

void main() {
  const targetAddress = '1HkqAaFZYDh2r9K67JoSiwf4ph7f2qZU1trBDu9nC3V';

  test('incoming tx parser accumulates outputs for target address', () {
    final tx = AlephiumTransaction.fromJson(
      {
        'hash': 'tx_in_1',
        'timestamp': '1731000000000',
        'blockHash': 'b1',
        'outputs': [
          {'address': targetAddress, 'attoAlphAmount': '2000000000000000000'},
          {'address': 'other', 'attoAlphAmount': '1000000000000000000'},
        ],
        'inputs': [
          {'address': 'sender', 'attoAlphAmount': '500000000000000000'},
        ],
        'gasAmount': '0',
        'gasPrice': '0',
      },
      targetAddress,
    );

    expect(tx.incomingAmount, BigInt.parse('2000000000000000000'));
    expect(tx.outgoingAmount, BigInt.zero);
    expect(tx.netAmount, BigInt.parse('2000000000000000000'));
    expect(tx.isIncoming, isTrue);
    expect(tx.fee, BigInt.zero);
  });

  test('outgoing tx parser subtracts fee when target is input', () {
    final tx = AlephiumTransaction.fromJson(
      {
        'hash': 'tx_out_1',
        'timestamp': '1731000000000',
        'blockHash': 'b2',
        'outputs': [
          {'address': 'other', 'attoAlphAmount': '500000000000000000'},
        ],
        'inputs': [
          {'address': targetAddress, 'attoAlphAmount': '3000000000000000000'},
        ],
        'gasAmount': '2',
        'gasPrice': '1000000000000',
      },
      targetAddress,
    );

    expect(tx.incomingAmount, BigInt.zero);
    expect(tx.outgoingAmount, BigInt.parse('3000000000000000000'));
    expect(tx.fee, BigInt.parse('2000000000000'));
    expect(tx.netAmount, BigInt.parse('-3000002000000000000'));
    expect(tx.isIncoming, isFalse);
  });

  test('parser tolerates missing fields gracefully', () {
    final tx = AlephiumTransaction.fromJson({}, targetAddress);

    expect(tx.hash, '');
    expect(tx.blockHash, '');
    expect(tx.incomingAmount, BigInt.zero);
    expect(tx.outgoingAmount, BigInt.zero);
    expect(tx.netAmount, BigInt.zero);
    expect(tx.fee, BigInt.zero);
  });

  test('timestamp parser handles seconds timestamp', () {
    final tx = AlephiumTransaction.fromJson(
      {
        'timestamp': '1731000000',
        'outputs': [
          {'address': targetAddress, 'attoAlphAmount': '1000000000000000000'},
        ],
      },
      targetAddress,
    );

    expect(tx.timestamp.isUtc, isFalse);
    expect(tx.timestamp.year, greaterThan(2024));
  });

  test('timestamp parser handles ISO timestamp', () {
    final tx = AlephiumTransaction.fromJson(
      {
        'timestamp': '2024-01-01T00:00:00Z',
        'outputs': [
          {'address': targetAddress, 'attoAlphAmount': '1000000000000000000'},
        ],
      },
      targetAddress,
    );

    expect(tx.timestamp.toUtc(), DateTime.parse('2024-01-01T00:00:00Z'));
  });

  test('timestamp parser handles microseconds timestamp', () {
    final tx = AlephiumTransaction.fromJson(
      {
        'timestamp': '1731000000000000',
        'outputs': [
          {'address': targetAddress, 'attoAlphAmount': '1000000000000000000'},
        ],
      },
      targetAddress,
    );

    expect(
        tx.timestamp.toUtc(),
        DateTime.fromMicrosecondsSinceEpoch(1731000000000000, isUtc: true)
            .toUtc());
  });
}
