import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/theme/app_tokens.dart';

class ResetWordmark extends StatelessWidget {
  const ResetWordmark({
    super.key,
    this.fontSize = 22,
    this.color,
    this.dotColor = AppColors.terracotta,
  });

  final double fontSize;
  final Color? color;
  final Color dotColor;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? context.palette.textPrimary;
    final dotSize = (fontSize * 0.25).clamp(4.0, 8.0);
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Text(
          'RESET',
          style: AppTheme.displayStyle(
            locale: 'en',
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
            color: effectiveColor,
            letterSpacing: fontSize * 0.08,
            height: 1.0,
          ),
        ),
        const SizedBox(width: 2),
        Padding(
          padding: EdgeInsets.only(bottom: fontSize * 0.14),
          child: Container(
            width: dotSize,
            height: dotSize,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }
}
