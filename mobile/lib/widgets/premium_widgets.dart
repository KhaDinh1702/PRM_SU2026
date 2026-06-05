import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sketchy_design_lang/sketchy_design_lang.dart' as sketchy;
import '../services/theme_service.dart';

// --- PREMIUM SKELETON SHIMMER LOADER ---
class ShimmerLoading extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerLoading({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 16.0,
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    // Chỉ repeat animation nếu KHÔNG ở chế độ sketchy
    if (!ThemeService.isSketchyMode.value) {
      _controller.repeat();
    }

    _animation = Tween<double>(begin: -2.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (ThemeService.isSketchyMode.value) {
      return sketchy.SketchyCard(
        child: SizedBox(
          width: widget.width,
          height: widget.height,
          child: const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
              ),
            ),
          ),
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final baseColor = isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.03);
    final highlightColor = isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.07);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(_animation.value - 1, -0.3),
              end: Alignment(_animation.value + 1, 0.3),
              colors: [
                baseColor,
                highlightColor,
                baseColor,
              ],
              stops: const [0.35, 0.5, 0.65],
            ),
          ),
        );
      },
    );
  }
}

// --- SMOOTH FADE-IN & SLIDE ANIMATION WIDGET ---
class FadeInSlide extends StatefulWidget {
  final Widget child;
  final int delayMs;
  final double slideOffset;

  const FadeInSlide({
    super.key,
    required this.child,
    this.delayMs = 0,
    this.slideOffset = 30.0,
  });

  @override
  State<FadeInSlide> createState() => _FadeInSlideState();
}

class _FadeInSlideState extends State<FadeInSlide> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<double> _slideAnimation;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _slideAnimation = Tween<double>(begin: widget.slideOffset, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    if (widget.delayMs > 0) {
      _timer = Timer(Duration(milliseconds: widget.delayMs), () {
        if (mounted) _controller.forward();
      });
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Transform.translate(
            offset: Offset(0, _slideAnimation.value),
            child: widget.child,
          ),
        );
      },
    );
  }
}

// --- ULTIMATE GLASSMORPHIC CARD ---
class GlassCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final List<BoxShadow>? boxShadow;

  const GlassCard({
    super.key,
    required this.child,
    this.borderRadius = 24.0,
    this.padding = const EdgeInsets.all(20.0),
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    if (ThemeService.isSketchyMode.value) {
      return sketchy.SketchyCard(
        child: Padding(
          padding: padding,
          child: child,
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final cardBgColor = isDark 
        ? Colors.white.withOpacity(0.015) 
        : Colors.white.withOpacity(0.7);

    final borderColor = isDark 
        ? Colors.white.withOpacity(0.05) 
        : Colors.black.withOpacity(0.04);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: boxShadow ?? [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.15 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: cardBgColor,
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(color: borderColor, width: 1),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

// --- PREMIUM CUSTOM INPUT FIELD ---
class PremiumInputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hintText;
  final IconData prefixIcon;
  final TextInputType keyboardType;

  const PremiumInputField({
    super.key,
    required this.controller,
    required this.label,
    required this.hintText,
    required this.prefixIcon,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hintColor = isDark ? Colors.white30 : Colors.black38;

    if (ThemeService.isSketchyMode.value) {
      return sketchy.SketchyTextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: hintColor, fontSize: 13, fontWeight: FontWeight.w500),
          hintText: hintText,
          hintStyle: TextStyle(color: hintColor, fontSize: 13),
          prefixIcon: Icon(prefixIcon, color: hintColor, size: 20),
        ),
      );
    }
    
    final bgInputColor = isDark 
        ? Colors.white.withOpacity(0.02) 
        : Colors.black.withOpacity(0.02);

    final borderColor = isDark 
        ? Colors.white.withOpacity(0.06) 
        : Colors.black.withOpacity(0.06);

    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);

    return Container(
      decoration: BoxDecoration(
        color: bgInputColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: hintColor, fontSize: 13, fontWeight: FontWeight.w500),
          hintText: hintText,
          hintStyle: TextStyle(color: hintColor, fontSize: 13),
          prefixIcon: Icon(prefixIcon, color: hintColor, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        style: TextStyle(color: textColor, fontSize: 14),
      ),
    );
  }
}

// --- ADAPTIVE PREMIUM/SKECHY BUTTON ---
class PremiumButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget? child;
  final Color? backgroundColor;
  final IconData? icon;
  final String? label;

  const PremiumButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.backgroundColor,
  }) : icon = null, label = null;

  const PremiumButton.icon({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.label,
    this.backgroundColor,
  }) : child = null;

  @override
  Widget build(BuildContext context) {
    final themeColor = backgroundColor ?? const Color(0xFF8B5CF6);

    if (ThemeService.isSketchyMode.value) {
      if (icon != null && label != null) {
        return sketchy.SketchyButton(
          onPressed: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16),
                const SizedBox(width: 6),
                sketchy.SketchyText(
                  label!,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ],
            ),
          ),
        );
      }
      
      Widget finalChild = child ?? const SizedBox();
      if (finalChild is Text) {
        finalChild = sketchy.SketchyText(
          finalChild.data ?? '',
          style: finalChild.style ?? const TextStyle(fontWeight: FontWeight.bold),
        );
      }

      return sketchy.SketchyButton(
        onPressed: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: finalChild,
        ),
      );
    }

    if (icon != null && label != null) {
      return ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18, color: Colors.white),
        label: Text(label!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: themeColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );
    }

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: themeColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: child,
    );
  }
}
