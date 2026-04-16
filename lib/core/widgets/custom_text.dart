import 'package:flutter/material.dart';

class CustomText extends StatelessWidget {
  final String text;
  final double? fontSize;
  final FontWeight? fontWeight;
  final Color? color;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final double? height;
  final double? letterSpacing;
  final TextDecoration? decoration;

  const CustomText(
      this.text, {
        super.key,
        this.fontSize,
        this.fontWeight,
        this.color,
        this.textAlign,
        this.maxLines,
        this.overflow,
        this.height,
        this.letterSpacing,
        this.decoration,
      });

  // ── Named constructors for common styles ──────────────

  const CustomText.heading(this.text, {super.key,
        this.color,
        this.textAlign,
        this.maxLines,
        this.overflow,
      })  : fontSize = 22,
        fontWeight = FontWeight.w800,
        height = null,
        letterSpacing = null,
        decoration = null;

  const CustomText.title(
      this.text, {
        super.key,
        this.color,
        this.textAlign,
        this.maxLines,
        this.overflow,
      })  : fontSize = 18,
        fontWeight = FontWeight.w700,
        height = null,
        letterSpacing = null,
        decoration = null;

  const CustomText.subtitle(
      this.text, {
        super.key,
        this.color,
        this.textAlign,
        this.maxLines,
        this.overflow,
      })  : fontSize = 15,
        fontWeight = FontWeight.w600,
        height = null,
        letterSpacing = null,
        decoration = null;

  const CustomText.body(
      this.text, {
        super.key,
        this.color,
        this.textAlign,
        this.maxLines,
        this.overflow,
      })  : fontSize = 14,
        fontWeight = FontWeight.w400,
        height = 1.6,
        letterSpacing = null,
        decoration = null;

  const CustomText.small(
      this.text, {
        super.key,
        this.color,
        this.textAlign,
        this.maxLines,
        this.overflow,
      })  : fontSize = 12,
        fontWeight = FontWeight.w400,
        height = null,
        letterSpacing = null,
        decoration = null;

  const CustomText.label(
      this.text, {
        super.key,
        this.color,
        this.textAlign,
        this.maxLines,
        this.overflow,
      })  : fontSize = 11,
        fontWeight = FontWeight.w600,
        height = null,
        letterSpacing = 0.5,
        decoration = null;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      style: TextStyle(
        fontFamily: 'Nunito',
        fontSize: fontSize ?? 14,
        fontWeight: fontWeight ?? FontWeight.w400,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
        decoration: decoration,
      ),
    );
  }
}