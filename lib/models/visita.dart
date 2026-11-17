/// Entidad principal de la app: una visita a un restaurante.
///
/// Es una clase inmutable que solo guarda datos y sabe convertirse
/// a/desde un `Map` para SQLite. No conoce nada de la interfaz ni de la
/// base de datos (Responsabilidad Única).
class Visita {
  final int? id;
  final String restaurante;

  /// Lo que pedí en esa visita.
  final String pedido;
  final String meGusto;
  final String noMeGusto;

  /// Calificación general, de 1 a 5.
  final int calificacion;

  /// Ruta de la foto del platillo dentro del almacenamiento persistente.
  final String? rutaFoto;
  final double? latitud;
  final double? longitud;
  final DateTime fecha;

  const Visita({
    this.id,
    required this.restaurante,
    required this.pedido,
    this.meGusto = '',
    this.noMeGusto = '',
    this.calificacion = 4,
    this.rutaFoto,
    this.latitud,
    this.longitud,
    required this.fecha,
  });

  bool get tieneUbicacion => latitud != null && longitud != null;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'restaurante': restaurante,
      'pedido': pedido,
      'me_gusto': meGusto,
      'no_me_gusto': noMeGusto,
      'calificacion': calificacion,
      'ruta_foto': rutaFoto,
      'latitud': latitud,
      'longitud': longitud,
      'fecha': fecha.toIso8601String(),
    };
  }

  factory Visita.fromMap(Map<String, Object?> map) {
    return Visita(
      id: map['id'] as int?,
      restaurante: map['restaurante'] as String,
      pedido: (map['pedido'] as String?) ?? '',
      meGusto: (map['me_gusto'] as String?) ?? '',
      noMeGusto: (map['no_me_gusto'] as String?) ?? '',
      calificacion: (map['calificacion'] as int?) ?? 4,
      rutaFoto: map['ruta_foto'] as String?,
      latitud: (map['latitud'] as num?)?.toDouble(),
      longitud: (map['longitud'] as num?)?.toDouble(),
      fecha: DateTime.parse(map['fecha'] as String),
    );
  }
}
