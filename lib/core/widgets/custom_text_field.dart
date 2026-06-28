import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class CustomTextField extends StatelessWidget {
  final String label;
  final String hint;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final int? maxLines;
  final bool readOnly;
  final VoidCallback? onTap;
  final String? Function(String?)? validator;
  final Color? fillColor;
  final double borderRadius;
  final Color? borderColor;
  final Color? focusedBorderColor;
  final Color? prefixIconColor;
  final Color? suffixIconColor;

  const CustomTextField({
    super.key,
    required this.label,
    required this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.readOnly = false,
    this.onTap,
    this.validator,
    this.fillColor = Colors.white,
    this.borderRadius = 12,
    this.borderColor = AppColors.border,
    this.focusedBorderColor = AppColors.primary,
    this.prefixIconColor,
    this.suffixIconColor,
  });

  @override
  Widget build(BuildContext context) {
    final borderSide = borderColor == Colors.transparent
        ? BorderSide.none
        : BorderSide(color: borderColor ?? AppColors.border);

    final focusedBorderSide = focusedBorderColor == Colors.transparent
        ? BorderSide.none
        : BorderSide(color: focusedBorderColor ?? AppColors.primary, width: 1.5);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
        ],
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          maxLines: maxLines,
          readOnly: readOnly,
          onTap: onTap,
          validator: validator,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.textSecondary),
            prefixIcon: prefixIcon != null && prefixIconColor != null
                ? IconTheme(
                    data: IconThemeData(color: prefixIconColor),
                    child: prefixIcon!,
                  )
                : prefixIcon,
            suffixIcon: suffixIcon != null && suffixIconColor != null
                ? IconTheme(
                    data: IconThemeData(color: suffixIconColor),
                    child: suffixIcon!,
                  )
                : suffixIcon,
            filled: true,
            fillColor: fillColor,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              borderSide: borderSide,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              borderSide: borderSide,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              borderSide: focusedBorderSide,
            ),
          ),
        ),
      ],
    );
  }
}
