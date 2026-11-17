import 'dart:io';

import 'package:flutter/material.dart';

/// Foto de una visita envuelta en un [Hero].
///
/// Se usa con el mismo [tag] en la lista y en el detalle, así Flutter anima
/// la foto al pasar de una pantalla a la otra.
class FotoVisita extends StatelessWidget {
  final String ruta;
  final Object tag;
  final double? ancho;
  final double? alto;
  final int cacheAncho;

  const FotoVisita({
    super.key,
    required this.ruta,
    required this.tag,
    this.ancho,
    this.alto,
    this.cacheAncho = 800,
  });

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: tag,
      child: Image.file(
        File(ruta),
        width: ancho,
        height: alto,
        fit: BoxFit.cover,
        // Decodifica la imagen a menor resolución para ahorrar memoria.
        cacheWidth: cacheAncho,
        errorBuilder: (_, __, ___) => SizedBox(
          width: ancho,
          height: alto,
          child: const Center(child: Icon(Icons.broken_image_outlined)),
        ),
      ),
    );
  }
}
