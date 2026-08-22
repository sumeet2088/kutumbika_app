import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/phone.dart';
import '../utils/ui.dart';

class PhoneField extends StatelessWidget {
  const PhoneField({
    super.key,
    required this.controller,
    required this.country,
    required this.onCountryChanged,
    this.label = 'Mobile number',
    this.enabled = true,
  });

  final TextEditingController controller;
  final DialCountry country;
  final ValueChanged<DialCountry> onCountryChanged;
  final String label;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 118,
          child: InputDecorator(
            decoration: fieldDecoration(label: 'Code'),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: country.iso,
                isExpanded: true,
                isDense: true,
                items: [
                  for (final c in dialCountries)
                    DropdownMenuItem(
                      value: c.iso,
                      child: Text(c.label, overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: enabled
                    ? (iso) {
                        if (iso == null) return;
                        onCountryChanged(
                          dialCountries.firstWhere((c) => c.iso == iso),
                        );
                      }
                    : null,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextFormField(
            controller: controller,
            enabled: enabled,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d+\s-]')),
              LengthLimitingTextInputFormatter(country.nationalMax + 6),
            ],
            style: bodyStyle(weight: FontWeight.w500),
            validator: (value) {
              final raw = value?.trim() ?? '';
              if (raw.isEmpty) return 'Enter mobile number';
              if (toE164(raw, country: country) == null) {
                return '${country.name} mobiles are ${country.nationalMin}${country.nationalMin == country.nationalMax ? '' : '–${country.nationalMax}'} digits';
              }
              return null;
            },
            decoration: fieldDecoration(
              label: label,
              hint: 'National number',
            ),
          ),
        ),
      ],
    );
  }
}
