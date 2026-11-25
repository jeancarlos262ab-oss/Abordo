import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/logo.dart';
import 'drivers_tab.dart';
import 'settings_tab.dart';
import 'today_tab.dart';
import 'units_tab.dart';

class _Tab {
  const _Tab(this.title, this.icon, this.selectedIcon, this.builder);
  final String title;
  final IconData icon;
  final IconData selectedIcon;
  final WidgetBuilder builder;
}

/// Estructura del dueño: 4 pestañas con icono y nombre siempre visibles, y un título grande
/// por pestaña (así siempre se sabe dónde se está).
class OwnerShell extends StatefulWidget {
  const OwnerShell({super.key});

  @override
  State<OwnerShell> createState() => _OwnerShellState();
}

class _OwnerShellState extends State<OwnerShell> {
  int _index = 0;

  static final _tabs = [
    _Tab('Hoy', Icons.insights_outlined, Icons.insights_rounded, (_) => const TodayTab()),
    _Tab('Unidades', Icons.directions_bus_outlined, Icons.directions_bus_rounded, (_) => const UnitsTab()),
    _Tab('Choferes', Icons.groups_outlined, Icons.groups_rounded, (_) => const DriversTab()),
    _Tab('Ajustes', Icons.settings_outlined, Icons.settings_rounded, (_) => const SettingsTab()),
  ];

  @override
  Widget build(BuildContext context) {
    final tab = _tabs[_index];
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      // Solo se construye la pestaña visible: las demás liberan sus consultas y temporizadores.
      body: SafeArea(
        bottom: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: Dimens.maxContentWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(Dimens.pagePadding, 18, Dimens.pagePadding, 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Semantics(
                          header: true,
                          child: Text(tab.title, style: text.headlineLarge, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                      Logo(size: 14, color: p.muted),
                    ],
                  ),
                ),
                Expanded(child: tab.builder(context)),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(border: Border(top: BorderSide(color: p.border))),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: [for (final t in _tabs) NavigationDestination(icon: Icon(t.icon), selectedIcon: Icon(t.selectedIcon), label: t.title)],
        ),
      ),
    );
  }
}
