import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            title: const Text('Cuenta'),
            subtitle: const Text('Gestiona tu sesión y datos personales'),
            leading: Icon(Icons.person_outline, color: colorScheme.primary),
            onTap: () => context.go('/login'),
          ),
          const Divider(),
          ListTile(
            title: const Text('Notificaciones'),
            subtitle: const Text('Configura recordatorios diarios'),
            leading: Icon(Icons.notifications_none, color: colorScheme.primary),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            title: const Text('Preferencias'),
            subtitle: const Text('Traducción, tamaño de letra, tema'),
            leading: Icon(Icons.tune, color: colorScheme.primary),
            onTap: () {},
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 6),
            child: Text(
              'Versión preliminar',
              style: textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}
