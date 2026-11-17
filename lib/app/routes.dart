import 'package:flutter/material.dart';

import '../models/visita.dart';
import '../screens/detalle_screen.dart';
import '../screens/formulario_screen.dart';
import '../screens/lista_screen.dart';
import 'app_dependencies.dart';

/// Nombres de las rutas de la app, en un solo lugar para evitar errores de
/// escritura al navegar.
class Rutas {
  static const String lista = '/';
  static const String detalle = '/detalle';
  static const String formulario = '/nueva';
}

/// Construye cada pantalla según el nombre de la ruta y le inyecta sus
/// dependencias. Se usa como `onGenerateRoute` del MaterialApp.
Route<dynamic> generarRuta(RouteSettings settings, AppDependencies deps) {
  switch (settings.name) {
    case Rutas.lista:
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => ListaScreen(repositorio: deps.repositorio),
      );

    case Rutas.detalle:
      // La visita seleccionada viaja como argumento de la ruta.
      final visita = settings.arguments as Visita;
      return MaterialPageRoute<bool>(
        settings: settings,
        builder: (_) => DetalleScreen(
          visita: visita,
          repositorio: deps.repositorio,
          imagenes: deps.imagenes,
          mapas: deps.mapas,
        ),
      );

    case Rutas.formulario:
      // Transición propia: el formulario sube desde abajo con un fundido.
      return PageRouteBuilder<bool>(
        settings: settings,
        transitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (_, __, ___) => FormularioScreen(
          repositorio: deps.repositorio,
          imagenes: deps.imagenes,
          ubicacion: deps.ubicacion,
          crearDictado: deps.crearDictado,
        ),
        transitionsBuilder: (_, animacion, __, hijo) {
          final curva = CurvedAnimation(
            parent: animacion,
            curve: Curves.easeOutCubic,
          );
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(curva),
            child: FadeTransition(opacity: animacion, child: hijo),
          );
        },
      );

    default:
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Ruta no encontrada')),
          body: Center(child: Text('No existe la ruta ${settings.name}')),
        ),
      );
  }
}
