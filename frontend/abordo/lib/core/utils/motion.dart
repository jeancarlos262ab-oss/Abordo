import 'package:flutter/widgets.dart';

/// Respeta "Reducir movimiento" del sistema: sin animaciones decorativas.
bool reduceMotion(BuildContext context) => MediaQuery.disableAnimationsOf(context);
