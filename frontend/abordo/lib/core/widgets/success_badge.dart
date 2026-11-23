import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Check grande que "salta" al aparecer, con un anillo que se expande. Confirma el pago.
class SuccessBadge extends StatelessWidget {
  const SuccessBadge({super.key, this.size = 110});
  final double size;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOutBack,
        builder: (_, v, __) => SizedBox(
          width: size * 1.8,
          height: size * 1.8,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Opacity(
                opacity: (1 - v).clamp(0.0, 1.0).toDouble() * .5,
                child: Container(width: size * (.8 + v), height: size * (.8 + v), decoration: const BoxDecoration(color: AppColors.success)),
              ),
              Transform.scale(
                scale: v.clamp(0.0, 1.15).toDouble(),
                child: Container(
                  width: size,
                  height: size,
                  decoration: const BoxDecoration(color: AppColors.success),
                  child: Icon(Icons.check_rounded, size: size * .62, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
