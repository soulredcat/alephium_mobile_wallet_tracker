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
          {'address': 'recipient', 'attoAlphAmount': '1000000000000000000'},
        ],
        'inputs': [
          {'address': 'sender', 'attoAlphAmount': '3000000000000000000'},
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
    expect(tx.fromAddress, 'sender');
    expect(tx.fee, BigInt.zero);
  });

  test('outgoing UTXO tx derives net change from input and change output once',
      () {
    final tx = AlephiumTransaction.fromJson(
      {
        'hash': 'tx_out_1',
        'timestamp': '1731000000000',
        'blockHash': 'b2',
        'outputs': [
          {'address': 'recipient', 'attoAlphAmount': '500000000000000000'},
          {'address': targetAddress, 'attoAlphAmount': '2499998000000000000'},
        ],
        'inputs': [
          {'address': targetAddress, 'attoAlphAmount': '3000000000000000000'},
        ],
        'gasAmount': '2',
        'gasPrice': '1000000000000',
      },
      targetAddress,
    );

    expect(tx.incomingAmount, BigInt.parse('2499998000000000000'));
    expect(tx.outgoingAmount, BigInt.parse('3000000000000000000'));
    expect(tx.fee, BigInt.parse('2000000000000'));
    expect(tx.netAmount, BigInt.parse('-500002000000000000'));
    expect(tx.toAddress, 'recipient');
    expect(tx.isIncoming, isFalse);
  });

  test('cache serialization preserves transaction counterparties', () {
    final original = AlephiumTransaction(
      hash: 'hash',
      timestamp: DateTime.parse('2026-08-10T00:00:00Z'),
      blockHash: 'block',
      netAmount: BigInt.from(-10),
      incomingAmount: BigInt.zero,
      outgoingAmount: BigInt.from(10),
      fee: BigInt.one,
      fromAddress: targetAddress,
      toAddress: 'recipient',
      scriptOk: true,
      coinbase: false,
    );

    final restored = AlephiumTransaction.fromCache(original.toJson());

    expect(restored.hash, original.hash);
    expect(restored.fromAddress, targetAddress);
    expect(restored.toAddress, 'recipient');
    expect(restored.netAmount, BigInt.from(-10));
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
          .toUtc(),
    );
  });

  test('timestamp parser handles milliseconds timestamp', () {
    final tx = AlephiumTransaction.fromJson(
      {
        'timestamp': '1731000000000',
        'outputs': [
          {'address': targetAddress, 'attoAlphAmount': '1000000000000000000'},
        ],
      },
      targetAddress,
    );

    expect(
      tx.timestamp.toUtc(),
      DateTime.fromMillisecondsSinceEpoch(1731000000000, isUtc: true).toUtc(),
    );
  });
}
