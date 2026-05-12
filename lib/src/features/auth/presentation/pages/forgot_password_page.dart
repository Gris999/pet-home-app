import 'package:flutter/material.dart';
import 'package:pethome_app/src/features/auth/data/auth_service.dart';
import 'package:pethome_app/src/features/auth/presentation/pages/reset_password_page.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({
    super.key,
    required this.authService,
  });

  final AuthService authService;

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _correoController = TextEditingController();

  bool _isLoading = false;
  String? _message;
  String? _errorMessage;

  @override
  void dispose() {
    _correoController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isLoading = true;
      _message = null;
      _errorMessage = null;
    });

    try {
      final message = await widget.authService.forgotPassword(
        correo: _correoController.text.trim(),
      );
      if (!mounted) return;
      setState(() => _message = message);
    } on AuthException catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorMessage = 'No se pudo procesar la solicitud.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Olvide mi contrasena')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Recupera tu acceso',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Ingresa tu correo. Por seguridad, siempre mostraremos una respuesta generica.',
          ),
          const SizedBox(height: 24),
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _correoController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Correo',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (value) {
                    final email = value?.trim() ?? '';
                    if (email.isEmpty) return 'El correo es obligatorio';
                    if (!email.contains('@')) return 'Ingresa un correo valido';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Enviar enlace'),
                ),
              ],
            ),
          ),
          if (_message != null) ...[
            const SizedBox(height: 16),
            _MessageBox(
              message: _message!,
              color: Colors.green.shade50,
              textColor: Colors.green.shade800,
              icon: Icons.check_circle_outline,
            ),
          ],
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            _MessageBox(
              message: _errorMessage!,
              color: Colors.red.shade50,
              textColor: Colors.red.shade800,
              icon: Icons.error_outline,
            ),
          ],
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ResetPasswordPage(authService: widget.authService),
                ),
              );
            },
            child: const Text('Ya tengo un token'),
          ),
        ],
      ),
    );
  }
}

class _MessageBox extends StatelessWidget {
  const _MessageBox({
    required this.message,
    required this.color,
    required this.textColor,
    required this.icon,
  });

  final String message;
  final Color color;
  final Color textColor;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: textColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: textColor),
            ),
          ),
        ],
      ),
    );
  }
}
