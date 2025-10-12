//Widget personalizado para mostrar un campo de texto (TextField)

import 'package:flutter/material.dart';

class CitaTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final String? value;
  final bool readOnly;
  final int maxLines;
  final TextEditingController? controller;
  final VoidCallback? onTap;

  const CitaTextField({
    super.key,
    required this.label,
    this.hint,
    this.value,
    this.readOnly = false,
    this.maxLines = 1,
    this.controller,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final TextEditingController internalCtrl =
        controller ?? TextEditingController(text: value ?? "");

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: internalCtrl,
        readOnly: readOnly,
        maxLines: maxLines,
        onTap: onTap,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: const TextStyle(color: Colors.green),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.green.shade400),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
