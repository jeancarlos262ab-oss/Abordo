import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Logotipo tipográfico de la landing: ABORDO, Red Hat Display 900 con tracking amplio.
/// Sin `color`, toma el color de texto del tema.
class Logo extends StatelessWidget {
  const Logo({super.key, this.size = 28, this.color});
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) => Semantics(
        header: true,
        label: 'ABORDO',
        child: ExcludeSemantics(
          child: Text(
            'ABORDO',
            style: GoogleFonts.redHatDisplay(
              fontSize: size,
              fontWeight: FontWeight.w900,
              letterSpacing: size * .14,
              color: color ?? Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      );
}
