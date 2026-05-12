import 'package:flutter/material.dart';
import 'package:pethome_app/src/features/auth/data/auth_service.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({
    super.key,
    required this.authService,
    this.initialToken,
  });

  final AuthService authService;
  final String? initialToken;

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _tokenController =
      TextEditingController(text: widget.initialToken ?? '');
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _isLoading = false;
  String? _message;
  String? _errorMessage;

  @override
  void dispose() {
    _tokenController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_passwordController.text != _confirmController.text) {
      setState(() => _errorMessage = 'Las contrasenas no coinciden.');
      return;
    }

    setState(() {
      _isLoading = true;
      _message = null;
      _errorMessage = null;
    });

    try {
      final message = await widget.authService.resetPassword(
        token: _tokenController.text.trim(),
        nuevaPassword: _passwordController.text,
      );
      if (!mounted) return;
      setState(() => _message = message);
    } on AuthException catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorMessage = 'No se pudo restablecer la contrasena.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Restablecer contrasena')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Define tu nueva contrasena',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Pega el token que recibiste por correo o abre esta pantalla con el token precargado.',
          ),
          const SizedBox(height: 24),
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _tokenController,
                  decoration: const InputDecoration(
                    labelText: 'Token',
                    prefixIcon: Icon(Icons.key_outlined),
                  ),
                  validator: (value) {
                    if ((value?.trim() ?? '').isEmpty) return 'El token es obligatorio';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Nueva contrasena',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  validator: (value) {
                    if ((value ?? '').length < 8) {
                      return 'Minimo 8 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _confirmController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirmar contrasena',
                    prefixIcon: Icon(Icons.lock_reset_outlined),
                  ),
                  validator: (value) {
                    if ((value ?? '').isEmpty) return 'Confirma tu contrasena';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Guardar nueva contrasena'),
                ),
              ],
            ),
          ),
          if (_message != null) ...[
            const SizedBox(height: 16),
            Text(_message!, style: TextStyle(color: Colors.green.shade700)),
          ],
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Text(_errorMessage!, style: TextStyle(color: Colors.red.shade700)),
          ],
        ],
      ),
    );
  }
}
