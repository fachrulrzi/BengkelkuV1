import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isOutlined;
  final Widget? icon;
  final double borderRadius;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? borderColor;
  final double height;
  final double fontSize;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.icon,
    this.borderRadius = 12,
    this.backgroundColor,
    this.textColor,
    this.borderColor,
    this.height = 50,
    this.fontSize = 14,
  });

  @override
  Widget build(BuildContext context) {
    final defaultTextColor = isOutlined ? AppColors.textPrimary : Colors.white;
    final finalTextColor = textColor ?? defaultTextColor;

    final defaultBgColor = isOutlined ? Colors.transparent : AppColors.primary;
    final finalBgColor = backgroundColor ?? defaultBgColor;

    final defaultBorderSide = isOutlined
        ? const BorderSide(color: AppColors.border)
        : BorderSide.none;
    final finalBorderSide = borderColor != null
        ? BorderSide(color: borderColor!)
        : defaultBorderSide;

    return SizedBox(
      width: double.infinity,
      height: height,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: finalBgColor,
          foregroundColor: finalTextColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            side: finalBorderSide,
          ),
        ),
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(finalTextColor),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    icon!,
                    const SizedBox(width: 8),
                  ],
                  Text(
                    text,
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w600,
                      color: finalTextColor,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
