import 'package:flutter/material.dart';

import '../models/visita.dart';
import '../utils/formato.dart';
import 'foto_visita.dart';

/// Tarjeta de una visita para la lista. Solo muestra datos: no sabe cómo se
/// guardan ni qué pasa al tocarla (eso lo decide quien la usa con [onTap]).
class VisitaCard extends StatelessWidget {
  final Visita visita;
  final VoidCallback onTap;

  const VisitaCard({super.key, required this.visita, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              _construirMiniatura(tema),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      visita.restaurante,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: tema.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      visita.pedido,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: tema.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(Formato.estrellas(visita.calificacion)),
                    Text(
                      Formato.fecha(visita.fecha),
                      style: tema.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (visita.tieneUbicacion)
                Icon(Icons.place, color: tema.colorScheme.primary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _construirMiniatura(ThemeData tema) {
    final ruta = visita.rutaFoto;

    if (ruta == null) {
      return Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: tema.colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: const Text('🍽️', style: TextStyle(fontSize: 32)),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: FotoVisita(
        ruta: ruta,
        tag: 'foto-${visita.id}',
        ancho: 72,
        alto: 72,
        cacheAncho: 216,
      ),
    );
  }
}
