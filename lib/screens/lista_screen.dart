import 'package:flutter/material.dart';

import '../app/routes.dart';
import '../data/visita_repository.dart';
import '../models/visita.dart';
import '../widgets/app_drawer.dart';
import '../widgets/visita_card.dart';

/// Pantalla principal: lista de visitas guardadas en SQLite.
///
/// Usa un [FutureBuilder] para cargar los datos de forma asíncrona y
/// recarga la lista cada vez que se regresa del formulario o del detalle.
class ListaScreen extends StatefulWidget {
  final VisitaRepository repositorio;

  const ListaScreen({super.key, required this.repositorio});

  @override
  State<ListaScreen> createState() => _ListaScreenState();
}

class _ListaScreenState extends State<ListaScreen> {
  late Future<List<Visita>> _visitas;

  @override
  void initState() {
    super.initState();
    _visitas = widget.repositorio.obtenerTodas();
  }

  void _recargar() {
    setState(() {
      _visitas = widget.repositorio.obtenerTodas();
    });
  }

  Future<void> _abrirFormulario() async {
    final guardado = await Navigator.pushNamed(context, Rutas.formulario);
    if (guardado == true) _recargar();
  }

  Future<void> _abrirDetalle(Visita visita) async {
    final cambio = await Navigator.pushNamed(
      context,
      Rutas.detalle,
      arguments: visita,
    );
    if (cambio == true) _recargar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Catador')),
      drawer: AppDrawer(onNuevaVisita: _abrirFormulario),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirFormulario,
        icon: const Icon(Icons.add_a_photo_outlined),
        label: const Text('Nueva visita'),
      ),
      body: FutureBuilder<List<Visita>>(
        future: _visitas,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _construirError(snapshot.error);
          }

          final visitas = snapshot.data ?? [];
          if (visitas.isEmpty) {
            return const _EstadoVacio();
          }

          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 88),
            itemCount: visitas.length,
            itemBuilder: (context, indice) {
              final visita = visitas[indice];
              return VisitaCard(
                visita: visita,
                onTap: () => _abrirDetalle(visita),
              );
            },
          );
        },
      ),
    );
  }

  Widget _construirError(Object? error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$error',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: _recargar, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}

/// Mensaje que se muestra cuando todavía no hay visitas.
class _EstadoVacio extends StatelessWidget {
  const _EstadoVacio();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🍽️', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 12),
            Text(
              'Aún no has catado ningún restaurante',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            const Text(
              'Toca "Nueva visita" para guardar la primera.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
