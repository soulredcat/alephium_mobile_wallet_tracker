import 'package:flutter/material.dart';

import '../models/alephium_address.dart';
import '../utils/alephium_formats.dart';

class AddressSelector extends StatelessWidget {
  const AddressSelector({
    required this.addresses,
    required this.selectedAddress,
    required this.onChanged,
    super.key,
  });

  final List<AlephiumAddress> addresses;
  final String? selectedAddress;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final effectiveSelected =
        addresses.any((item) => item.address == selectedAddress)
            ? selectedAddress
            : null;

    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        isExpanded: true,
        value: effectiveSelected,
        hint: const Text('Select address'),
        icon: const Icon(Icons.expand_more),
        onChanged: (value) {
          if (value != null) {
            onChanged(value);
          }
        },
        items: addresses
            .map(
              (item) => DropdownMenuItem(
                value: item.address,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.label,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    Text(
                      formatShortAddress(item.address),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}
