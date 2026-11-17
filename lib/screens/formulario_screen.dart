import 'dart:io';

import 'package:flutter/material.dart';

import '../data/app_exception.dart';
import '../data/visita_repository.dart';
import '../models/visita.dart';
import '../services/dictation_service.dart';
import '../services/image_service.dart';
import '../services/location_service.dart';
import '../utils/formato.dart';
import '../widgets/historial_restaurante.dart';

/// Campo de texto que se puede dictar con el micrófono.
enum CampoDictado { meGusto, noMeGusto }

/// Formulario para registrar una visita nueva.
///
/// Usa tres "gadgets" del teléfono:
/// * Cámara o galería: foto de lo que pedí.
/// * Micrófono: dictar lo que me gustó y lo que no.
/// * GPS: se captura la ubicación al guardar.
///
/// Además, al escribir un restaurante que ya visité, muestra lo que pedí y
/// lo que opiné la vez pasada.
class FormularioScreen extends StatefulWidget {
  final VisitaRepository repositorio;
  final ImageService imagenes;
  final LocationService ubicacion;
  final DictationService Function() crearDictado;

  const FormularioScreen({
    super.key,
    required this.repositorio,
    required this.imagenes,
    required this.ubicacion,
    required this.crearDictado,
  });

  @override
  State<FormularioScreen> createState() => _FormularioScreenState();
}

class _FormularioScreenState extends State<FormularioScreen> {
  final _formKey = GlobalKey<FormState>();
  final _restauranteCtrl = TextEditingController();
  final _restauranteFocus = FocusNode();
  final _pedidoCtrl = TextEditingController();
  final _meGustoCtrl = TextEditingController();
  final _noMeGustoCtrl = TextEditingController();

  late final DictationService _dictado;

  int _calificacion = 4;
  String? _rutaFoto;
  bool _guardado = false;
  bool _guardando = false;
  CampoDictado? _campoDictando;

  List<String> _conocidos = [];
  List<Visita> _anteriores = [];
  String _restauranteConsultado = '';

  @override
  void initState() {
    super.initState();
    _dictado = widget.crearDictado();
    _cargarRestaurantesConocidos();
  }

  @override
  void dispose() {
    // Se libera el micrófono y los controladores al salir de la pantalla.
    _dictado.cancelar();
    _restauranteCtrl.dispose();
    _restauranteFocus.dispose();
    _pedidoCtrl.dispose();
    _meGustoCtrl.dispose();
    _noMeGustoCtrl.dispose();

    // Si se tomó una foto pero la visita no se guardó, la foto queda huérfana.
    final foto = _rutaFoto;
    if (!_guardado && foto != null) {
      widget.imagenes.eliminarFoto(foto);
    }
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Historial del restaurante
  // ---------------------------------------------------------------------------

  Future<void> _cargarRestaurantesConocidos() async {
    try {
      final nombres = await widget.repositorio.obtenerRestaurantes();
      if (mounted) setState(() => _conocidos = nombres);
    } on AppException {
      // Las sugerencias son un extra: si fallan, el formulario sigue igual.
    }
  }

  /// Si el nombre coincide con un restaurante ya visitado, carga su historial.
  Future<void> _alCambiarRestaurante(String texto) async {
    final nombre = texto.trim().toLowerCase();

    String? coincidencia;
    for (final conocido in _conocidos) {
      if (conocido.toLowerCase() == nombre) {
        coincidencia = conocido;
        break;
      }
    }

    if (coincidencia == null) {
      if (_anteriores.isNotEmpty) {
        setState(() {
          _anteriores = [];
          _restauranteConsultado = '';
        });
      }
      return;
    }

    if (coincidencia.toLowerCase() == _restauranteConsultado) return;
    _restauranteConsultado = coincidencia.toLowerCase();

    try {
      final visitas = await widget.repositorio.obtenerDeRestaurante(coincidencia);
      if (mounted) setState(() => _anteriores = visitas);
    } on AppException {
      // Igual que arriba: el historial es opcional.
    }
  }

  // ---------------------------------------------------------------------------
  // Foto
  // ---------------------------------------------------------------------------

  Future<void> _elegirFoto(Future<String?> Function() accion) async {
    try {
      final nueva = await accion();
      if (nueva == null || !mounted) return;

      // Si ya había una foto sin guardar, se descarta.
      final anterior = _rutaFoto;
      if (anterior != null) {
        await widget.imagenes.eliminarFoto(anterior);
      }
      setState(() => _rutaFoto = nueva);
    } on AppException catch (e) {
      _mostrarMensaje(e.mensaje);
    }
  }

  // ---------------------------------------------------------------------------
  // Dictado
  // ---------------------------------------------------------------------------

  Future<void> _alternarDictado(CampoDictado campo) async {
    final estabaEnEsteCampo = _campoDictando == campo;

    // Se detiene cualquier dictado en curso antes de empezar otro.
    if (_dictado.escuchando) {
      await _dictado.detener();
    }
    if (estabaEnEsteCampo) {
      if (mounted) setState(() => _campoDictando = null);
      return;
    }

    final controlador = campo == CampoDictado.meGusto ? _meGustoCtrl : _noMeGustoCtrl;
    final base = controlador.text.trimRight();

    setState(() => _campoDictando = campo);

    try {
      await _dictado.iniciar(
        onTexto: (texto) {
          if (!mounted) return;
          final completo = base.isEmpty ? texto : '$base $texto';
          controlador.value = TextEditingValue(
            text: completo,
            selection: TextSelection.collapsed(offset: completo.length),
          );
        },
        onFin: () {
          if (mounted && _campoDictando == campo) {
            setState(() => _campoDictando = null);
          }
        },
        onError: _mostrarMensaje,
      );
    } on AppException catch (e) {
      if (mounted) setState(() => _campoDictando = null);
      _mostrarMensaje(e.mensaje);
    }
  }

  // ---------------------------------------------------------------------------
  // Guardar
  // ---------------------------------------------------------------------------

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _guardando = true);
    await _dictado.detener();

    // La ubicación se captura en el momento de guardar. Si falla, la visita
    // se guarda igual, solo que sin coordenadas.
    Coordenadas? coordenadas;
    try {
      coordenadas = await widget.ubicacion.obtenerUbicacionActual();
    } on AppException catch (e) {
      _mostrarMensaje('Guardé la visita sin ubicación. ${e.mensaje}');
    }

    final visita = Visita(
      restaurante: _restauranteCtrl.text.trim(),
      pedido: _pedidoCtrl.text.trim(),
      meGusto: _meGustoCtrl.text.trim(),
      noMeGusto: _noMeGustoCtrl.text.trim(),
      calificacion: _calificacion,
      rutaFoto: _rutaFoto,
      latitud: coordenadas?.latitud,
      longitud: coordenadas?.longitud,
      fecha: DateTime.now(),
    );

    try {
      await widget.repositorio.insertar(visita);
      _guardado = true;
      if (mounted) Navigator.pop(context, true);
    } on AppException catch (e) {
      if (mounted) setState(() => _guardando = false);
      _mostrarMensaje(e.mensaje);
    }
  }

  void _mostrarMensaje(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje)));
  }

  // ---------------------------------------------------------------------------
  // Interfaz
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva visita')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _construirRestaurante(),
              HistorialRestaurante(
                titulo: '📖 La última vez que viniste',
                visitas: _anteriores,
                maximo: 2,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _pedidoCtrl,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Lo que pedí',
                  border: OutlineInputBorder(),
                ),
                validator: (valor) => (valor == null || valor.trim().isEmpty)
                    ? 'Escribe qué pediste'
                    : null,
              ),
              const SizedBox(height: 16),
              _construirFoto(),
              const SizedBox(height: 16),
              _construirCampoDictable(
                campo: CampoDictado.meGusto,
                controlador: _meGustoCtrl,
                etiqueta: '👍 Lo que me gustó',
              ),
              const SizedBox(height: 12),
              _construirCampoDictable(
                campo: CampoDictado.noMeGusto,
                controlador: _noMeGustoCtrl,
                etiqueta: '👎 Lo que no me gustó',
              ),
              const SizedBox(height: 16),
              _construirCalificacion(),
              const SizedBox(height: 8),
              const Text('📍 La ubicación se guarda automáticamente al guardar.'),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _guardando ? null : _guardar,
                icon: _guardando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check),
                label: const Text('Guardar visita'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Campo del restaurante con sugerencias de los ya visitados.
  Widget _construirRestaurante() {
    return LayoutBuilder(
      builder: (context, restricciones) {
        return RawAutocomplete<String>(
          textEditingController: _restauranteCtrl,
          focusNode: _restauranteFocus,
          optionsBuilder: (valor) {
            final texto = valor.text.trim().toLowerCase();
            if (texto.isEmpty) return const Iterable<String>.empty();
            return _conocidos.where((n) => n.toLowerCase().contains(texto));
          },
          onSelected: _alCambiarRestaurante,
          fieldViewBuilder: (context, controlador, foco, alEnviar) {
            return TextFormField(
              controller: controlador,
              focusNode: foco,
              textCapitalization: TextCapitalization.words,
              onChanged: _alCambiarRestaurante,
              decoration: const InputDecoration(
                labelText: 'Restaurante',
                prefixIcon: Icon(Icons.storefront_outlined),
                border: OutlineInputBorder(),
              ),
              validator: (valor) => (valor == null || valor.trim().isEmpty)
                  ? 'Escribe el nombre del restaurante'
                  : null,
            );
          },
          optionsViewBuilder: (context, alSeleccionar, opciones) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(8),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: 200,
                    maxWidth: restricciones.maxWidth,
                  ),
                  child: ListView(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    children: [
                      for (final opcion in opciones)
                        ListTile(
                          dense: true,
                          leading: const Icon(Icons.history, size: 20),
                          title: Text(opcion),
                          onTap: () => alSeleccionar(opcion),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _construirFoto() {
    final ruta = _rutaFoto;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Foto de lo que pediste',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        if (ruta != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              File(ruta),
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              cacheWidth: 1080,
            ),
          ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _elegirFoto(widget.imagenes.tomarFoto),
                icon: const Icon(Icons.photo_camera_outlined),
                label: const Text('Cámara'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _elegirFoto(widget.imagenes.elegirDeGaleria),
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Galería'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Campo de varias líneas con un botón de micrófono para dictar.
  Widget _construirCampoDictable({
    required CampoDictado campo,
    required TextEditingController controlador,
    required String etiqueta,
  }) {
    final dictando = _campoDictando == campo;

    return TextFormField(
      controller: controlador,
      minLines: 2,
      maxLines: 5,
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(
        labelText: etiqueta,
        alignLabelWithHint: true,
        border: const OutlineInputBorder(),
        helperText: dictando ? 'Escuchando... habla ahora' : null,
        suffixIcon: IconButton(
          tooltip: dictando ? 'Detener dictado' : 'Dictar con voz',
          icon: Icon(
            dictando ? Icons.stop_circle : Icons.mic_none,
            color: dictando ? Colors.red : null,
          ),
          onPressed: () => _alternarDictado(campo),
        ),
      ),
    );
  }

  Widget _construirCalificacion() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Calificación: ${Formato.estrellas(_calificacion)}  ${Formato.etiqueta(_calificacion)}',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        Slider(
          value: _calificacion.toDouble(),
          min: 1,
          max: 5,
          divisions: 4,
          label: Formato.etiqueta(_calificacion),
          onChanged: (valor) => setState(() => _calificacion = valor.round()),
        ),
      ],
    );
  }
}
