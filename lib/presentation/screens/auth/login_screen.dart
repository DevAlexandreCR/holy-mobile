import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Iniciar sesión'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Bienvenido de nuevo',
              style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Text(
              'Ingresa para continuar con tu experiencia bíblica.',
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            TextField(
              decoration: const InputDecoration(labelText: 'Correo electrónico'),
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(labelText: 'Contraseña'),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/verse'),
              child: const Text('Entrar (placeholder)'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.go('/forgot-password'),
              child: const Text('¿Olvidaste tu contraseña?'),
            ),
            TextButton(
              onPressed: () => context.go('/register'),
              child: const Text('Crear cuenta nueva'),
            ),
          ],
        ),
      ),
    );
  }
}
