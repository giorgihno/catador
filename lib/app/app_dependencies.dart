import '../data/sqlite_visita_repository.dart';
import '../data/visita_repository.dart';
import '../services/dictation_service.dart';
import '../services/image_service.dart';
import '../services/location_service.dart';
import '../services/map_launcher.dart';

/// Contenedor sencillo de dependencias.
///
/// Es el único lugar donde se decide qué implementación concreta se usa para
/// cada contrato. Las pantallas reciben las abstracciones por constructor y
/// nunca crean ni conocen las clases concretas (Inversión de Dependencias).
class AppDependencies {
  final VisitaRepository repositorio;
  final ImageService imagenes;
  final LocationService ubicacion;
  final MapLauncher mapas;

  /// El dictado tiene estado (está escuchando o no), así que cada formulario
  /// crea su propia instancia en lugar de compartir una.
  final DictationService Function() crearDictado;

  const AppDependencies({
    required this.repositorio,
    required this.imagenes,
    required this.ubicacion,
    required this.mapas,
    required this.crearDictado,
  });

  /// Configuración real de la app.
  factory AppDependencies.produccion() {
    return AppDependencies(
      repositorio: SqliteVisitaRepository(),
      imagenes: ImagePickerService(),
      ubicacion: GeolocatorLocationService(),
      mapas: GoogleMapsLauncher(),
      crearDictado: () => SpeechDictationService(),
    );
  }
}
