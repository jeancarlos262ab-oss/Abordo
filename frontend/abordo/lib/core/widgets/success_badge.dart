import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_icons.dart';

/// Check grande que "salta" al aparecer, con halos que se expanden. Confirma el pago.
class SuccessBadge extends StatelessWidget {
  const SuccessBadge({super.key, this.size = 104});
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ExcludeSemantics(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOutBack,
        builder: (_, v, __) => SizedBox(
          width: size * 1.7,
          height: size * 1.7,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Opacity(
                opacity: (1 - v).clamp(0.0, 1.0).toDouble() * .6,
                child: Container(width: size * (.9 + .7 * v), height: size * (.9 + .7 * v), decoration: BoxDecoration(shape: BoxShape.circle, color: p.success.withOpacity(.4))),
              ),
              Container(width: size * 1.28, height: size * 1.28, decoration: BoxDecoration(shape: BoxShape.circle, color: p.successSoft)),
              Transform.scale(
                scale: v.clamp(0.0, 1.15).toDouble(),
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.success,
                  ),
                  child: Icon(AppIcons.check, size: size * .58, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
