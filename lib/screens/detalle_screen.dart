import 'package:flutter/material.dart';

import '../data/app_exception.dart';
import '../data/visita_repository.dart';
import '../models/visita.dart';
import '../services/image_service.dart';
import '../services/map_launcher.dart';
import '../utils/formato.dart';
import '../widgets/foto_visita.dart';
import '../widgets/historial_restaurante.dart';

/// Detalle de una visita: foto (con animación Hero), lo que pedí, lo que me
/// gustó y lo que no, un botón para abrir el lugar en Google Maps y el
/// historial de visitas anteriores al mismo restaurante.
///
/// Devuelve `true` al cerrarse si la visita fue eliminada, para que la lista
/// se recargue.
class DetalleScreen extends StatefulWidget {
  final Visita visita;
  final VisitaRepository repositorio;
  final ImageService imagenes;
  final MapLauncher mapas;

  const DetalleScreen({
    super.key,
    required this.visita,
    required this.repositorio,
    required this.imagenes,
    required this.mapas,
  });

  @override
  State<DetalleScreen> createState() => _DetalleScreenState();
}

class _DetalleScreenState extends State<DetalleScreen> {
  late final Future<List<Visita>> _anteriores;

  @override
  void initState() {
    super.initState();
    _anteriores = widget.repositorio.obtenerDeRestaurante(
      widget.visita.restaurante,
      excluirId: widget.visita.id,
    );
  }

  void _mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje)));
  }

  Future<void> _abrirMapa() async {
    final visita = widget.visita;
    try {
      await widget.mapas.abrir(visita.latitud!, visita.longitud!);
    } on AppException catch (e) {
      if (mounted) _mostrarMensaje(e.mensaje);
    }
  }

  Future<void> _confirmarEliminar() async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar visita'),
        content: Text(
          '¿Seguro que quieres borrar tu visita a ${widget.visita.restaurante}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmado != true) return;
    await _eliminar();
  }

  Future<void> _eliminar() async {
    final visita = widget.visita;
    try {
      await widget.repositorio.eliminar(visita.id!);
      final ruta = visita.rutaFoto;
      if (ruta != null) {
        await widget.imagenes.eliminarFoto(ruta);
      }
      if (mounted) Navigator.pop(context, true);
    } on AppException catch (e) {
      if (mounted) _mostrarMensaje(e.mensaje);
    }
  }

  @override
  Widget build(BuildContext context) {
    final visita = widget.visita;
    final tema = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(visita.restaurante),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Eliminar',
            onPressed: _confirmarEliminar,
          ),
        ],
      ),
      body: ListView(
        children: [
          if (visita.rutaFoto != null)
            FotoVisita(
              ruta: visita.rutaFoto!,
              tag: 'foto-${visita.id}',
              ancho: double.infinity,
              alto: 280,
              cacheAncho: 1080,
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  visita.restaurante,
                  style: tema.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(Formato.fecha(visita.fecha), style: tema.textTheme.bodySmall),
                const SizedBox(height: 8),
                Text(
                  '${Formato.estrellas(visita.calificacion)}  ${Formato.etiqueta(visita.calificacion)}',
                  style: tema.textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                _Seccion(titulo: '🍽️ Lo que pedí', texto: visita.pedido),
                _Seccion(titulo: '👍 Lo que me gustó', texto: visita.meGusto),
                _Seccion(titulo: '👎 Lo que no me gustó', texto: visita.noMeGusto),
                const SizedBox(height: 8),
                _construirUbicacion(),
                const SizedBox(height: 16),
                _construirHistorial(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirUbicacion() {
    final visita = widget.visita;

    if (!visita.tieneUbicacion) {
      return const Text('📍 Esta visita se guardó sin ubicación.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '📍 ${visita.latitud!.toStringAsFixed(5)}, ${visita.longitud!.toStringAsFixed(5)}',
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: _abrirMapa,
          icon: const Icon(Icons.map_outlined),
          label: const Text('Abrir en Google Maps'),
        ),
      ],
    );
  }

  Widget _construirHistorial() {
    return FutureBuilder<List<Visita>>(
      future: _anteriores,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Text(
            '${snapshot.error}',
            style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          );
        }
        return HistorialRestaurante(
          titulo: 'Otras veces que fui',
          visitas: snapshot.data ?? [],
        );
      },
    );
  }
}

/// Bloque con un título y un texto. No se muestra si el texto está vacío.
class _Seccion extends StatelessWidget {
  final String titulo;
  final String texto;

  const _Seccion({required this.titulo, required this.texto});

  @override
  Widget build(BuildContext context) {
    if (texto.trim().isEmpty) return const SizedBox.shrink();

    final tema = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: tema.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(texto, style: tema.textTheme.bodyLarge),
        ],
      ),
    );
  }
}
