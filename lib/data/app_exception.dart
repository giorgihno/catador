/// Error propio de la app con un mensaje que sí se le puede mostrar al
/// usuario. Las capas de datos y servicios convierten los errores técnicos
/// (SQLite, permisos, plugins) en esta excepción, así la interfaz no depende
/// de los detalles de cada librería.
class AppException implements Exception {
  final String mensaje;

  const AppException(this.mensaje);

  @override
  String toString() => mensaje;
}
