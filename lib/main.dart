import 'package:flutter/material.dart';

import 'app/app_dependencies.dart';
import 'app/routes.dart';

void main() {
  runApp(CatadorApp(dependencias: AppDependencies.produccion()));
}

/// Raíz de la aplicación. Configura el tema y la navegación por rutas.
class CatadorApp extends StatelessWidget {
  final AppDependencies dependencias;

  const CatadorApp({super.key, required this.dependencias});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Catador',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.deepOrange, useMaterial3: true),
      initialRoute: Rutas.lista,
      onGenerateRoute: (settings) => generarRuta(settings, dependencias),
    );
  }
}
