import 'dart:async';

import 'package:geolocator/geolocator.dart';

import '../data/app_exception.dart';

/// Par de coordenadas GPS.
class Coordenadas {
  final double latitud;
  final double longitud;

  const Coordenadas(this.latitud, this.longitud);
}

/// Contrato para obtener la ubicación actual del usuario.
abstract class LocationService {
  Future<Coordenadas> obtenerUbicacionActual();
}

/// Implementación con el paquete geolocator.
class GeolocatorLocationService implements LocationService {
  @override
  Future<Coordenadas> obtenerUbicacionActual() async {
    try {
      final gpsActivo = await Geolocator.isLocationServiceEnabled();
      if (!gpsActivo) {
        throw const AppException('El GPS está apagado. Actívalo para guardar el lugar.');
      }

      var permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
      }
      if (permiso == LocationPermission.denied) {
        throw const AppException('Sin permiso de ubicación no puedo guardar el lugar.');
      }
      if (permiso == LocationPermission.deniedForever) {
        throw const AppException(
          'El permiso de ubicación está bloqueado. Actívalo desde los ajustes del teléfono.',
        );
      }

      final posicion = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      return Coordenadas(posicion.latitude, posicion.longitude);
    } on AppException {
      rethrow;
    } on TimeoutException {
      throw const AppException('El GPS tardó demasiado en responder.');
    } catch (e) {
      throw const AppException('No se pudo obtener la ubicación.');
    }
  }
}
