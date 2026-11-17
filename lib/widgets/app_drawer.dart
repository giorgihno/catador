import 'package:flutter/material.dart';

import '../app/routes.dart';

/// Menú lateral de la app. Solo navega: la acción de "Nueva visita" y el
/// refresco de la lista los decide la pantalla que lo usa mediante
/// [onNuevaVisita].
class AppDrawer extends StatelessWidget {
  final VoidCallback onNuevaVisita;

  const AppDrawer({super.key, required this.onNuevaVisita});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: tema.colorScheme.primary),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🍴', style: TextStyle(fontSize: 40)),
                  Text(
                    'Catador',
                    style: tema.textTheme.headlineSmall?.copyWith(
                      color: tema.colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Tu diario de restaurantes',
                    style: TextStyle(color: tema.colorScheme.onPrimary),
                  ),
                ],
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.restaurant_menu),
            title: const Text('Mis visitas'),
            onTap: () {
              Navigator.pop(context);
              Navigator.popUntil(context, ModalRoute.withName(Rutas.lista));
            },
          ),
          ListTile(
            leading: const Icon(Icons.add_a_photo_outlined),
            title: const Text('Nueva visita'),
            onTap: () {
              Navigator.pop(context);
              onNuevaVisita();
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Acerca de'),
            onTap: () {
              Navigator.pop(context);
              showAboutDialog(
                context: context,
                applicationName: 'Catador',
                applicationVersion: '1.0.0',
                applicationIcon: const Text('🍴', style: TextStyle(fontSize: 32)),
                children: const [
                  Text(
                    'Guarda qué pediste, qué te gustó y qué no en cada '
                    'restaurante, con foto, voz y ubicación.',
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
