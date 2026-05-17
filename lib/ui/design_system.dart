import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Design Tokens ───────────────────────────────────────────────────────────
const bgPrimary     = Color(0xFF050508);
const bgSecondary   = Color(0xFF0D0D14);
const bgTertiary    = Color(0xFF0A0A10);
const surface       = Color(0xFF12121C);
const surfaceLight  = Color(0xFF1A1A28);
const textPrimary   = Color(0xFFF0F0FF);
const textSecondary = Color(0xFF8888AA);
const accentCritical = Color(0xFFFF4466);
const accentWarning  = Color(0xFFFFBF00);
const accentSafe     = Color(0xFF00FFB2);
const accentInfo     = Color(0xFF00C2FF);
const accentPurple   = Color(0xFF7B61FF);

// ── Typography ───────────────────────────────────────────────────────────────
TextStyle syne(double size, {FontWeight weight = FontWeight.w600, Color color = textPrimary, double? letterSpacing}) =>
    GoogleFonts.syne(fontSize: size, fontWeight: weight, color: color, letterSpacing: letterSpacing);

TextStyle inter(double size, {FontWeight weight = FontWeight.w400, Color color = textPrimary, double? letterSpacing}) =>
    GoogleFonts.inter(fontSize: size, fontWeight: weight, color: color, letterSpacing: letterSpacing);

// ── GlassCard ────────────────────────────────────────────────────────────────
class GlassCard extends StatelessWidget {
  final Widget child;
  final Color? accentColor;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;

  const GlassCard({super.key, required this.child, this.accentColor, this.borderRadius = 16, this.padding});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white.withOpacity(0.07), Colors.white.withOpacity(0.02)],
            ),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: accentColor?.withOpacity(0.25) ?? Colors.white.withOpacity(0.06),
              width: 0.5,
            ),
            boxShadow: accentColor != null
                ? [
                    BoxShadow(color: accentColor!.withOpacity(0.12), blurRadius: 20),
                    BoxShadow(color: accentColor!.withOpacity(0.05), blurRadius: 40, spreadRadius: -4),
                  ]
                : [],
          ),
          child: child,
        ),
      ),
    );
  }
}

// ── Status dot ───────────────────────────────────────────────────────────────
class StatusDot extends StatelessWidget {
  final Color color;
  final double size;
  const StatusDot({super.key, required this.color, this.size = 8});

  @override
  Widget build(BuildContext context) => Container(
        width: size, height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: color.withOpacity(0.6), blurRadius: 6)]),
      );
}
