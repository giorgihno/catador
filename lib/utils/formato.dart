/// Funciones pequeñas para mostrar datos con formato legible.
class Formato {
  static const List<String> _meses = [
    'ene', 'feb', 'mar', 'abr', 'may', 'jun',
    'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
  ];

  static const List<String> _etiquetas = [
    '',
    'Meh',
    'Regular',
    'Rico',
    'Muy rico',
    '¡Épico!',
  ];

  /// Ejemplo: "15 nov 2026, 13:31".
  static String fecha(DateTime fecha) {
    String dos(int n) => n.toString().padLeft(2, '0');
    return '${fecha.day} ${_meses[fecha.month - 1]} ${fecha.year}, '
        '${dos(fecha.hour)}:${dos(fecha.minute)}';
  }

  /// Ejemplo: 3 -> "⭐⭐⭐".
  static String estrellas(int calificacion) => '⭐' * calificacion;

  /// Ejemplo: 5 -> "¡Épico!".
  static String etiqueta(int calificacion) => _etiquetas[calificacion];
}
