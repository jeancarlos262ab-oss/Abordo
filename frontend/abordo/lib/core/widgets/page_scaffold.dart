import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import 'brand_hero.dart';

/// Esqueleto de pantalla: contenido centrado con ancho máximo y relleno uniforme.
///
/// * Sin `hero`: barra superior normal con `title` y `actions`.
/// * Con `hero`: cabecera de marca (degradado + ruta punteada) con el botón de regreso, el
///   `title` y las `actions` dentro de ella, y `hero` como contenido debajo de la barra.
class PageScaffold extends StatelessWidget {
  const PageScaffold({
    super.key,
    required this.child,
    this.title,
    this.actions,
    this.hero,
    this.scroll = true,
    this.bottomBar,
    this.floatingActionButton,
    this.showBack = true,
  });

  final Widget child;
  final String? title;
  final List<Widget>? actions;
  final Widget? hero;
  final bool scroll;
  final Widget? bottomBar;
  final Widget? floatingActionButton;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final hasHero = hero != null;
    final showBar = hasHero && (title != null || actions != null || (showBack && Navigator.of(context).canPop()));

    final body = hasHero
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BrandHero(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showBar) HeroTopBar(title: title, actions: actions, showBack: showBack) else const SizedBox(height: 16),
                    hero!,
                  ],
                ),
              ),
              Padding(padding: const EdgeInsets.fromLTRB(Dimens.pagePadding, 20, Dimens.pagePadding, 28), child: child),
            ],
          )
        : Padding(padding: const EdgeInsets.fromLTRB(Dimens.pagePadding, 8, Dimens.pagePadding, 32), child: child);

    final content = Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: Dimens.maxContentWidth),
        child: scroll ? SingleChildScrollView(child: body) : body,
      ),
    );

    return Scaffold(
      appBar: hasHero || (title == null && actions == null)
          ? null
          : AppBar(title: title == null ? null : Text(title!), actions: actions, automaticallyImplyLeading: showBack),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: hasHero ? SystemUiOverlayStyle.light : (Theme.of(context).brightness == Brightness.dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark),
        child: SafeArea(top: !hasHero, child: content),
      ),
      bottomNavigationBar: bottomBar,
      floatingActionButton: floatingActionButton,
    );
  }
}
