import '../utils/alephium_formats.dart';

class AlephiumTransaction {
  const AlephiumTransaction({
    required this.hash,
    required this.timestamp,
    required this.blockHash,
    required this.netAmount,
    required this.incomingAmount,
    required this.outgoingAmount,
    required this.fee,
    required this.fromAddress,
    required this.toAddress,
    required this.scriptOk,
    required this.coinbase,
  });

  final String hash;
  final DateTime timestamp;
  final String blockHash;

  /// Net ALPH balance change for the tracked address.
  ///
  /// Alephium uses a UTXO model. The transaction fee is already reflected in
  /// the difference between the tracked address' consumed inputs and outputs
  /// returning to it, so the fee must not be subtracted a second time.
  final BigInt netAmount;
  final BigInt incomingAmount;
  final BigInt outgoingAmount;
  final BigInt fee;
  final String fromAddress;
  final String toAddress;
  final bool scriptOk;
  final bool coinbase;

  bool get isIncoming => netAmount >= BigInt.zero;

  factory AlephiumTransaction.fromJson(
    Map<String, dynamic> json,
    String targetAddress,
  ) {
    final txTimestamp = _parseTimestamp(json['timestamp']);
    final blockHash = json['blockHash'] as String? ?? '';
    final hash = json['hash'] as String? ?? '';
    final scriptOk = json['scriptExecutionOk'] as bool? ?? true;
    final coinbase = json['coinbase'] as bool? ?? false;

    BigInt incoming = BigInt.zero;
    BigInt outgoing = BigInt.zero;
    String firstIncomingOther = '';
    String firstOutgoingOther = '';

    final outputs = (json['outputs'] as List<dynamic>?) ?? const [];
    for (final raw in outputs) {
      if (raw is! Map<String, dynamic>) {
        continue;
      }
      final address = raw['address'] as String? ?? '';
      if (address == targetAddress) {
        incoming += attoToBigInt(raw['attoAlphAmount']);
      } else if (firstIncomingOther.isEmpty && address.isNotEmpty) {
        firstIncomingOther = address;
      }
    }

    final inputs = (json['inputs'] as List<dynamic>?) ?? const [];
    for (final raw in inputs) {
      if (raw is! Map<String, dynamic>) {
        continue;
      }
      final address = raw['address'] as String? ?? '';
      if (address == targetAddress) {
        outgoing += attoToBigInt(raw['attoAlphAmount']);
      } else if (firstOutgoingOther.isEmpty && address.isNotEmpty) {
        firstOutgoingOther = address;
      }
    }

    final gasAmount = attoToBigInt(json['gasAmount']);
    final gasPrice = attoToBigInt(json['gasPrice']);
    final fee = gasAmount * gasPrice;

    return AlephiumTransaction(
      hash: hash,
      timestamp: txTimestamp,
      blockHash: blockHash,
      netAmount: incoming - outgoing,
      incomingAmount: incoming,
      outgoingAmount: outgoing,
      fee: fee,
      fromAddress: firstOutgoingOther,
      toAddress: firstIncomingOther,
      scriptOk: scriptOk,
      coinbase: coinbase,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hash': hash,
      'timestamp': timestamp.toIso8601String(),
      'blockHash': blockHash,
      'netAmount': netAmount.toString(),
      'incomingAmount': incomingAmount.toString(),
      'outgoingAmount': outgoingAmount.toString(),
      'fee': fee.toString(),
      'fromAddress': fromAddress,
      'toAddress': toAddress,
      'scriptOk': scriptOk,
      'coinbase': coinbase,
    };
  }

  factory AlephiumTransaction.fromCache(Map<String, dynamic> json) {
    return AlephiumTransaction(
      hash: json['hash'] as String? ?? '',
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ??
          DateTime.now(),
      blockHash: json['blockHash'] as String? ?? '',
      netAmount: attoToBigInt(json['netAmount']),
      incomingAmount: attoToBigInt(json['incomingAmount']),
      outgoingAmount: attoToBigInt(json['outgoingAmount']),
      fee: attoToBigInt(json['fee']),
      fromAddress: json['fromAddress'] as String? ?? '',
      toAddress: json['toAddress'] as String? ?? '',
      scriptOk: json['scriptOk'] as bool? ?? true,
      coinbase: json['coinbase'] as bool? ?? false,
    );
  }

  static DateTime _parseTimestamp(dynamic raw) {
    if (raw == null) {
      return DateTime.now();
    }

    if (raw is num) {
      return _parseEpochToDateTime(raw.toInt());
    }

    final asString = raw.toString().trim();
    if (asString.isEmpty) {
      return DateTime.now();
    }

    final parsedFromIso = DateTime.tryParse(asString);
    if (parsedFromIso != null) {
      return parsedFromIso.toLocal();
    }

    final parsedNumber = int.tryParse(asString);
    if (parsedNumber != null) {
      return _parseEpochToDateTime(parsedNumber);
    }

    return DateTime.now();
  }

  static DateTime _parseEpochToDateTime(int epochValue) {
    if (epochValue < 0) {
      return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true).toLocal();
    }

    // Alephium API timestamps can be seconds (10 digits), milliseconds (13 digits),
    // or microseconds (16 digits).
    if (epochValue < 10000000000) {
      return DateTime.fromMillisecondsSinceEpoch(
        epochValue * 1000,
        isUtc: true,
      ).toLocal();
    }

    if (epochValue < 10000000000000) {
      return DateTime.fromMillisecondsSinceEpoch(
        epochValue,
        isUtc: true,
      ).toLocal();
    }

    if (epochValue < 10000000000000000) {
      return DateTime.fromMicrosecondsSinceEpoch(
        epochValue,
        isUtc: true,
      ).toLocal();
    }

    return DateTime.fromMicrosecondsSinceEpoch(
      epochValue ~/ 1000,
      isUtc: true,
    ).toLocal();
  }
}
