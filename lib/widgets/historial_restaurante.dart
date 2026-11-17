import 'package:flutter/material.dart';

import '../models/visita.dart';
import '../utils/formato.dart';

/// Resumen de las visitas anteriores a un restaurante: qué pedí, qué me gustó
/// y qué no. Sirve para decidir qué pedir (o qué evitar) antes de ordenar.
class HistorialRestaurante extends StatelessWidget {
  final String titulo;
  final List<Visita> visitas;

  /// Cuántas visitas se muestran como máximo.
  final int maximo;

  const HistorialRestaurante({
    super.key,
    required this.titulo,
    required this.visitas,
    this.maximo = 3,
  });

  @override
  Widget build(BuildContext context) {
    if (visitas.isEmpty) return const SizedBox.shrink();

    final tema = Theme.of(context);
    final mostradas = visitas.take(maximo).toList();

    return Card(
      color: tema.colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titulo,
              style: tema.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            for (final visita in mostradas) ...[
              const Divider(height: 20),
              _construirVisita(tema, visita),
            ],
            if (visitas.length > maximo)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'y ${visitas.length - maximo} visita(s) más',
                  style: tema.textTheme.bodySmall,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _construirVisita(ThemeData tema, Visita visita) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${Formato.fecha(visita.fecha)}  ${Formato.estrellas(visita.calificacion)}',
          style: tema.textTheme.bodySmall,
        ),
        const SizedBox(height: 2),
        Text('Pedí: ${visita.pedido}'),
        if (visita.meGusto.isNotEmpty) Text('👍 ${visita.meGusto}'),
        if (visita.noMeGusto.isNotEmpty) Text('👎 ${visita.noMeGusto}'),
      ],
    );
  }
}
