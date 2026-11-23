/// Validadores de formularios. Los mensajes dicen qué hacer, no solo qué está mal.
abstract final class Validators {
  static String? Function(String?) notEmpty([String what = 'este dato']) =>
      (v) => (v ?? '').trim().isEmpty ? 'Escribe $what.' : null;

  static String? Function(String?) minLength(int n, String what) =>
      (v) => (v ?? '').trim().length < n ? '$what debe tener al menos $n caracteres.' : null;

  static String? Function(String?) digits(int min, int max, String what) => (v) {
        final t = (v ?? '').trim();
        if (!RegExp('^\\d{$min,$max}\$').hasMatch(t)) {
          return min == max ? '$what debe tener $min números.' : '$what debe tener de $min a $max números.';
        }
        return null;
      };

  static String? Function(String?) money(String what) => (v) {
        final n = double.tryParse((v ?? '').trim().replaceAll(',', '.'));
        return (n == null || n < 1 || n > 1000) ? '$what debe ser entre \$1 y \$1,000.' : null;
      };

  /// Campo opcional: vacío es válido; si trae algo, se valida con `inner`.
  static String? Function(String?) optional(String? Function(String?) inner) =>
      (v) => (v ?? '').trim().isEmpty ? null : inner(v);

  /// Aplica varios validadores en orden y regresa el primer error.
  static String? Function(String?) all(List<String? Function(String?)> list) => (v) {
        for (final f in list) {
          final e = f(v);
          if (e != null) return e;
        }
        return null;
      };
}
