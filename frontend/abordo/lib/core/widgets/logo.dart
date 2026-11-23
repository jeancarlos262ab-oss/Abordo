import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Logotipo tipográfico de la landing: ABORDO, Red Hat Display 900 con tracking amplio.
class Logo extends StatelessWidget {
  const Logo({super.key, this.size = 28});
  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
        header: true,
        label: 'ABORDO',
        child: ExcludeSemantics(
          child: Text(
            'ABORDO',
            style: GoogleFonts.redHatDisplay(fontSize: size, fontWeight: FontWeight.w900, letterSpacing: size * .12),
          ),
        ),
      );
}
