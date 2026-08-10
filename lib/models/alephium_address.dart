class AlephiumAddress {
  const AlephiumAddress({
    required this.address,
    required this.label,
    required this.createdAt,
    this.isDefault = false,
  });

  final String address;
  final String label;
  final DateTime createdAt;
  final bool isDefault;

  factory AlephiumAddress.fromJson(Map<String, dynamic> json) {
    return AlephiumAddress(
      address: json['address'] as String? ?? '',
      label: json['label'] as String? ?? 'Unknown',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'address': address,
      'label': label,
      'createdAt': createdAt.toIso8601String(),
      'isDefault': isDefault,
    };
  }

  AlephiumAddress copyWith({String? label, bool? isDefault}) {
    return AlephiumAddress(
      address: address,
      label: label ?? this.label,
      createdAt: createdAt,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}
