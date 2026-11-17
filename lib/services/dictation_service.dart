import 'package:speech_to_text/speech_to_text.dart';

import '../data/app_exception.dart';

/// Contrato para dictar texto con el micrófono (voz a texto).
abstract class DictationService {
  bool get escuchando;

  /// Empieza a escuchar.
  ///
  /// * [onTexto] recibe el texto reconocido hasta el momento.
  /// * [onFin] se llama cuando el dictado termina por cualquier motivo.
  /// * [onError] recibe un mensaje legible si algo falla durante la sesión.
  Future<void> iniciar({
    required void Function(String texto) onTexto,
    required void Function() onFin,
    required void Function(String mensaje) onError,
  });

  Future<void> detener();

  /// Cancela y libera recursos (se usa en dispose()).
  Future<void> cancelar();
}

/// Implementación con el paquete speech_to_text.
///
/// El paquete captura el audio del micrófono y lo transcribe con el
/// reconocedor de voz del sistema.
class SpeechDictationService implements DictationService {
  final SpeechToText _speech = SpeechToText();
  bool _inicializado = false;

  /// Idioma en el que se dicta. Se busca uno en español para que el
  /// reconocedor no use el idioma del sistema (en el emulador es inglés).
  String? _idioma;

  void Function()? _onFin;
  void Function(String mensaje)? _onError;

  @override
  bool get escuchando => _speech.isListening;

  Future<void> _inicializar() async {
    if (_inicializado) return;

    final disponible = await _speech.initialize(
      onStatus: (estado) {
        if (estado == 'done' || estado == 'notListening') {
          _onFin?.call();
        }
      },
      onError: (error) {
        _onError?.call('Error de dictado: ${error.errorMsg}');
        _onFin?.call();
      },
    );

    if (!disponible) {
      throw const AppException(
        'El dictado no está disponible. Revisa el permiso del micrófono y que el teléfono tenga reconocimiento de voz.',
      );
    }
    _idioma = await _buscarIdiomaEspanol();
    _inicializado = true;
  }

  /// Devuelve el identificador de un idioma en español disponible en el
  /// teléfono (primero México, luego Estados Unidos, luego España) o `null`
  /// si no hay ninguno y se debe usar el idioma del sistema.
  Future<String?> _buscarIdiomaEspanol() async {
    try {
      final idiomas = await _speech.locales();
      const preferidos = ['es_MX', 'es_US', 'es_ES'];

      for (final preferido in preferidos) {
        for (final idioma in idiomas) {
          if (idioma.localeId.replaceAll('-', '_') == preferido) {
            return idioma.localeId;
          }
        }
      }
      for (final idioma in idiomas) {
        if (idioma.localeId.toLowerCase().startsWith('es')) {
          return idioma.localeId;
        }
      }
    } catch (_) {
      // Si no se pueden listar los idiomas se usa el del sistema.
    }
    return null;
  }

  @override
  Future<void> iniciar({
    required void Function(String texto) onTexto,
    required void Function() onFin,
    required void Function(String mensaje) onError,
  }) async {
    try {
      await _inicializar();
      _onFin = onFin;
      _onError = onError;

      await _speech.listen(
        onResult: (resultado) => onTexto(resultado.recognizedWords),
        listenFor: const Duration(seconds: 60),
        pauseFor: const Duration(seconds: 5),
        localeId: _idioma,
        listenOptions: SpeechListenOptions(
          partialResults: true,
          listenMode: ListenMode.dictation,
        ),
      );
    } on AppException {
      rethrow;
    } catch (e) {
      throw const AppException('No se pudo iniciar el dictado.');
    }
  }

  @override
  Future<void> detener() async {
    try {
      await _speech.stop();
    } catch (_) {
      // Si ya estaba detenido no hay nada que hacer.
    }
  }

  @override
  Future<void> cancelar() async {
    _onFin = null;
    _onError = null;
    try {
      await _speech.cancel();
    } catch (_) {
      // Se ignora: se está cerrando la pantalla.
    }
  }
}