import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/motion.dart';
import 'drivers_tab.dart';
import 'owner_widgets.dart';
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

/// Estructura del dueño: barra superior compacta con el título de la pestaña y, abajo, una barra
/// flotante oscura donde la pestaña activa se abre en una píldora rosa con su nombre.
class OwnerShell extends StatefulWidget {
  const OwnerShell({super.key});

  @override
  State<OwnerShell> createState() => _OwnerShellState();
}

class _OwnerShellState extends State<OwnerShell> {
  int _index = 0;

  static final _tabs = [
    _Tab('Hoy', AppIcons.chartOutlined, AppIcons.chart, (_) => const TodayTab()),
    _Tab('Unidades', AppIcons.busOutlined, AppIcons.bus, (_) => const UnitsTab()),
    _Tab('Choferes', AppIcons.groupsOutlined, AppIcons.groups, (_) => const DriversTab()),
    _Tab('Ajustes', AppIcons.settingsOutlined, AppIcons.settings, (_) => const SettingsTab()),
  ];

  @override
  Widget build(BuildContext context) {
    final tab = _tabs[_index];
    final text = Theme.of(context).textTheme;
    final fade = reduceMotion(context) ? Duration.zero : const Duration(milliseconds: 220);

    return Scaffold(
      // Solo se construye la pestaña visible: las demás liberan sus consultas y temporizadores.
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: context.isDarkTheme ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Barra superior compacta: 48 px en total, mismo color que el fondo.
              SizedBox(
                height: 48,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: Dimens.maxContentWidth),
                    child: Padding(
                      padding: const EdgeInsets.only(left: Dimens.pagePadding, right: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Semantics(
                              header: true,
                              child: Text(tab.title, style: text.headlineMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: Dimens.maxContentWidth),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: AnimatedSwitcher(
                        duration: fade,
                        child: KeyedSubtree(key: ValueKey(_index), child: tab.builder(context)),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Dimens.pagePadding, 6, Dimens.pagePadding, 12),
          child: Align(
            alignment: Alignment.center,
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: Dimens.maxContentWidth - 2 * Dimens.pagePadding),
              child: Container(
                height: 66,
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(color: context.panelColor, borderRadius: BorderRadius.circular(99)),
                child: LayoutBuilder(
                  builder: (context, c) {
                    final selected = c.maxWidth * .38;
                    final other = (c.maxWidth - selected) / (_tabs.length - 1);
                    return Row(
                      children: [
                        for (var i = 0; i < _tabs.length; i++)
                          _NavItem(
                            tab: _tabs[i],
                            selected: i == _index,
                            width: i == _index ? selected : other,
                            duration: fade,
                            onTap: () => setState(() => _index = i),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.tab, required this.selected, required this.width, required this.duration, required this.onTap});
  final _Tab tab;
  final bool selected;
  final double width;
  final Duration duration;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      selected: selected,
      label: selected ? '${tab.title}, pestaña actual' : tab.title,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: selected
            ? null
            : () {
                HapticFeedback.selectionClick();
                onTap();
              },
        child: AnimatedContainer(
          duration: duration,
          curve: Curves.easeOutCubic,
          width: width,
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: selected ? AppColors.rose : Colors.transparent, borderRadius: BorderRadius.circular(99)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(selected ? tab.selectedIcon : tab.icon, size: 24, color: selected ? AppColors.ink : Colors.white.withOpacity(.72)),
              if (selected) ...[
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    tab.title,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.clip,
                    style: text.labelLarge?.copyWith(color: AppColors.ink),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
