import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../data/app_exception.dart';

/// Contrato para conseguir y administrar las fotos de las visitas.
abstract class ImageService {
  /// Abre la cámara. Devuelve la ruta persistente de la foto o `null` si
  /// el usuario canceló.
  Future<String?> tomarFoto();

  /// Abre la galería. Devuelve la ruta persistente o `null` si canceló.
  Future<String?> elegirDeGaleria();

  /// Borra una foto guardada (por ejemplo al eliminar una visita).
  Future<void> eliminarFoto(String ruta);
}

/// Implementación con el paquete image_picker.
class ImagePickerService implements ImageService {
  final ImagePicker _picker = ImagePicker();

  @override
  Future<String?> tomarFoto() => _obtener(ImageSource.camera);

  @override
  Future<String?> elegirDeGaleria() => _obtener(ImageSource.gallery);

  Future<String?> _obtener(ImageSource fuente) async {
    try {
      final archivo = await _picker.pickImage(
        source: fuente,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (archivo == null) return null;
      return await _guardarPermanente(archivo.path);
    } on FileSystemException {
      throw const AppException('No se pudo guardar la foto en el dispositivo.');
    } catch (e) {
      final origen = fuente == ImageSource.camera ? 'la cámara' : 'la galería';
      throw AppException('No se pudo usar $origen. Revisa los permisos.');
    }
  }

  /// image_picker deja la foto en una carpeta de caché que el sistema puede
  /// limpiar. Se copia al directorio de documentos para que la visita no
  /// pierda su imagen.
  Future<String> _guardarPermanente(String rutaOrigen) async {
    final documentos = await getApplicationDocumentsDirectory();
    final carpeta = Directory(p.join(documentos.path, 'fotos'));
    if (!await carpeta.exists()) {
      await carpeta.create(recursive: true);
    }

    final nombre = 'visita_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final copia = await File(rutaOrigen).copy(p.join(carpeta.path, nombre));
    return copia.path;
  }

  @override
  Future<void> eliminarFoto(String ruta) async {
    try {
      final archivo = File(ruta);
      if (await archivo.exists()) {
        await archivo.delete();
      }
    } on FileSystemException {
      // Si no se puede borrar, la visita se elimina igual; el archivo
      // huérfano no afecta al usuario.
    }
  }
}
