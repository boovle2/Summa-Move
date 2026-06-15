import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/app_state.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final email = TextEditingController(text: 'demo@example.com');
  final password = TextEditingController(text: 'password123');
  bool busy = false;
  String? error;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await ref.read(sessionProvider).login(email.text, password.text);
    } catch (exception) {
      setState(() => error =
          'Inloggen mislukt. Controleer je gegevens en de Laravel API.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                children: [
                  const Icon(Icons.fitness_center,
                      size: 84, color: Color(0xFFE91E63)),
                  const SizedBox(height: 18),
                  Text('Summa Move',
                      style: Theme.of(context)
                          .textTheme
                          .displaySmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('Klaar om vandaag in beweging te komen?'),
                  const SizedBox(height: 32),
                  TextField(
                      controller: email,
                      decoration: const InputDecoration(
                          labelText: 'E-mail', border: OutlineInputBorder())),
                  const SizedBox(height: 14),
                  TextField(
                      controller: password,
                      obscureText: true,
                      decoration: const InputDecoration(
                          labelText: 'Wachtwoord',
                          border: OutlineInputBorder())),
                  if (error != null)
                    Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(error!,
                            style: const TextStyle(color: Colors.red))),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: busy ? null : submit,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: busy
                            ? const CircularProgressIndicator()
                            : const Text('Inloggen'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: busy
                        ? null
                        : () {
                            email.text = 'admin@summamove.test';
                            password.text = 'password123';
                          },
                    child: const Text('Gebruik admin-demo'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
