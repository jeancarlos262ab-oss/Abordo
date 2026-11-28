import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/dialogs.dart';
import '../../owner/ui/owner_widgets.dart';
import '../state/avatar_provider.dart';
import '../state/session_controller.dart';

/// Un dato corto del perfil: cifra grande y etiqueta chica (p. ej. "3" / "Unidades").
class ProfileStat {
  const ProfileStat(this.value, this.label);
  final String value;
  final String label;
}

/// Cabecera de perfil compartida por pasajero, dueño y chofer: contorno delgado y sin fondo,
/// foto de perfil (la predeterminada hasta que la persona suba una), nombre, usuario, etiquetas
/// y, debajo, tres datos del rol.
class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    super.key,
    required this.name,
    required this.login,
    required this.roleLabel,
    required this.roleIcon,
    this.chips = const [],
    this.stats = const [],
  });

  final String name;
  final String login;
  final String roleLabel;
  final IconData roleIcon;

  /// Etiquetas extra junto al rol (p. ej. el nombre del negocio).
  final List<Widget> chips;
  final List<ProfileStat> stats;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final muted = context.palette.muted;
    final summary = stats.map((s) => '${s.label}: ${s.value}').join(', ');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Dimens.rXl),
        border: Border.all(color: context.inkAt(.32), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const ProfileAvatar(),
              const SizedBox(width: 14),
              Expanded(
                child: Semantics(
                  container: true,
                  label: '$name, usuario $login, $roleLabel',
                  child: ExcludeSemantics(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800), maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Text('@$login', style: text.bodyMedium?.copyWith(color: muted), maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 8),
                        Wrap(spacing: 6, runSpacing: 6, children: [OutlineChip(icon: roleIcon, label: roleLabel), ...chips]),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (stats.isNotEmpty) ...[
            const SizedBox(height: 14),
            Divider(height: 1, color: context.inkAt(.16)),
            const SizedBox(height: 12),
            Semantics(
              container: true,
              label: summary,
              child: ExcludeSemantics(
                child: Row(
                  children: [
                    for (var i = 0; i < stats.length; i++) ...[
                      if (i > 0) Container(width: 1, height: 34, color: context.inkAt(.16)),
                      Expanded(
                        child: Column(
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(stats[i].value, style: tabular(text.titleLarge?.copyWith(fontWeight: FontWeight.w800))),
                            ),
                            const SizedBox(height: 2),
                            Text(stats[i].label, style: text.bodySmall?.copyWith(color: muted), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

enum _PhotoAction { gallery, camera, remove }

/// Foto de perfil con un botón de cámara: toca para elegir de la galería, tomar una foto o quitarla.
/// Sin foto muestra la imagen predeterminada (silueta de persona). La foto se guarda en el servidor.
class ProfileAvatar extends ConsumerStatefulWidget {
  const ProfileAvatar({super.key, this.size = 76});
  final double size;

  @override
  ConsumerState<ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends ConsumerState<ProfileAvatar> {
  static const _maxBytes = 500 * 1024;
  bool _busy = false;

  /// Tipo de imagen según sus primeros bytes (lo que el servidor también comprueba).
  static String? _mimeOf(Uint8List b) {
    if (b.length > 3 && b[0] == 0xff && b[1] == 0xd8 && b[2] == 0xff) return 'image/jpeg';
    if (b.length > 8 && b[0] == 0x89 && b[1] == 0x50 && b[2] == 0x4e && b[3] == 0x47) return 'image/png';
    if (b.length > 12 && b[0] == 0x52 && b[1] == 0x49 && b[2] == 0x46 && b[3] == 0x46 && b[8] == 0x57 && b[9] == 0x45 && b[10] == 0x42 && b[11] == 0x50) return 'image/webp';
    return null;
  }

  Future<void> _choose(bool hasPhoto) async {
    final action = await showFormSheet<_PhotoAction>(
      context,
      title: 'Foto de perfil',
      builder: (ctx) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SheetRow(icon: AppIcons.image, label: 'Elegir de la galería', onTap: () => Navigator.of(ctx).pop(_PhotoAction.gallery)),
          _SheetRow(icon: AppIcons.camera, label: 'Tomar una foto', onTap: () => Navigator.of(ctx).pop(_PhotoAction.camera)),
          if (hasPhoto) _SheetRow(icon: AppIcons.trash, label: 'Quitar mi foto', danger: true, onTap: () => Navigator.of(ctx).pop(_PhotoAction.remove)),
        ],
      ),
    );
    if (action == null || !mounted) return;
    await _run(() async {
      final repo = ref.read(authRepositoryProvider);
      if (action == _PhotoAction.remove) {
        await repo.clearAvatar();
        return;
      }
      final file = await ImagePicker().pickImage(
        source: action == _PhotoAction.camera ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      if (file == null) throw const _Cancelled();
      final bytes = await file.readAsBytes();
      final mime = _mimeOf(bytes);
      if (mime == null) throw const ApiException('Elige una imagen JPG, PNG o WebP.');
      if (bytes.length > _maxBytes) throw const ApiException('La foto pesa demasiado. Elige una más ligera.');
      await repo.setAvatar('data:$mime;base64,${base64Encode(bytes)}');
    }, removed: action == _PhotoAction.remove);
  }

  Future<void> _run(Future<void> Function() job, {required bool removed}) async {
    setState(() => _busy = true);
    try {
      await job();
      ref.invalidate(avatarProvider);
      if (mounted) showMessage(context, removed ? 'Quitamos tu foto.' : 'Listo, guardamos tu foto.');
    } on _Cancelled {
      // la persona cerró el selector sin elegir nada
    } catch (e) {
      if (mounted) showMessage(context, e is ApiException ? e.message : 'No pudimos abrir la foto. Revisa los permisos e intenta de nuevo.', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final photo = ref.watch(avatarProvider).valueOrNull;
    final p = context.palette;
    final size = widget.size;
    return Semantics(
      button: true,
      label: photo == null ? 'Agregar foto de perfil' : 'Cambiar foto de perfil',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: _busy ? null : () => _choose(photo != null),
        child: SizedBox(
          width: size,
          height: size,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(shape: BoxShape.circle, color: p.field, border: Border.all(color: context.inkAt(.32), width: 1)),
                child: ClipOval(
                  child: photo != null
                      ? Image.memory(photo, fit: BoxFit.cover, gaplessPlayback: true)
                      : _DefaultAvatar(size: size),
                ),
              ),
              if (_busy)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black.withOpacity(.35)),
                    child: const Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))),
                  ),
                ),
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.ink, border: Border.all(color: p.background, width: 2)),
                  child: const Icon(AppIcons.camera, size: 14, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Cancelled implements Exception {
  const _Cancelled();
}

/// Imagen predeterminada: cabeza y hombros de una silueta, sin foto.
class _DefaultAvatar extends StatelessWidget {
  const _DefaultAvatar({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.inkAt(.35);
    return CustomPaint(size: Size.square(size), painter: _SilhouettePainter(c));
  }
}

class _SilhouettePainter extends CustomPainter {
  const _SilhouettePainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final w = size.width;
    final h = size.height;
    canvas.drawCircle(Offset(w / 2, h * .38), w * .19, paint);
    canvas.drawOval(Rect.fromCenter(center: Offset(w / 2, h * .98), width: w * .74, height: h * .6), paint);
  }

  @override
  bool shouldRepaint(_SilhouettePainter old) => old.color != color;
}

class _SheetRow extends StatelessWidget {
  const _SheetRow({required this.icon, required this.label, required this.onTap, this.danger = false});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? context.palette.danger : context.inkColor;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Dimens.rMd),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 52),
        child: Row(
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(width: 14),
            Expanded(child: Text(label, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: color))),
          ],
        ),
      ),
    );
  }
}

/// Botón "Cerrar sesión" en píldora, el mismo de los ajustes del dueño.
class LogoutPill extends StatelessWidget {
  const LogoutPill({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Cerrar sesión',
      excludeSemantics: true,
      child: Material(
        color: AppColors.pinkDeep,
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(AppIcons.signOut, size: 22, color: AppColors.ink),
                const SizedBox(width: 12),
                Text('Cerrar sesión', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.ink, fontSize: 15)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
