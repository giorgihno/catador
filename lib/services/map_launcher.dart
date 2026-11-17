import 'package:url_launcher/url_launcher.dart';

import '../data/app_exception.dart';

/// Contrato para abrir una ubicación en una app de mapas.
abstract class MapLauncher {
  Future<void> abrir(double latitud, double longitud);
}

/// Abre Google Maps con las coordenadas guardadas.
///
/// Usa un enlace web de Google Maps, así que no necesita API key: si la
/// app de Google Maps está instalada la abre, y si no, abre el navegador.
class GoogleMapsLauncher implements MapLauncher {
  @override
  Future<void> abrir(double latitud, double longitud) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$latitud,$longitud',
    );

    try {
      final abierto = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!abierto) {
        throw const AppException('No se pudo abrir Google Maps.');
      }
    } on AppException {
      rethrow;
    } catch (e) {
      throw const AppException('No se pudo abrir Google Maps.');
    }
  }
}
