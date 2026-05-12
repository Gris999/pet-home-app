import 'package:flutter/material.dart';
import 'package:pethome_app/src/features/auth/data/auth_service.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({
    super.key,
    required this.authService,
  });

  final AuthService authService;

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _actualController = TextEditingController();
  final _nuevaController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _isLoading = false;
  String? _message;
  String? _errorMessage;

  @override
  void dispose() {
    _actualController.dispose();
    _nuevaController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_nuevaController.text != _confirmController.text) {
      setState(() => _errorMessage = 'Las contrasenas no coinciden.');
      return;
    }

    setState(() {
      _isLoading = true;
      _message = null;
      _errorMessage = null;
    });

    try {
      final message = await widget.authService.changePassword(
        passwordActual: _actualController.text,
        nuevaPassword: _nuevaController.text,
      );
      if (!mounted) return;
      setState(() {
        _message = message;
        _actualController.clear();
        _nuevaController.clear();
        _confirmController.clear();
      });
    } on AuthException catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorMessage = 'No se pudo actualizar la contrasena.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cambiar contrasena')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _actualController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Contrasena actual'),
                  validator: (value) =>
                      (value ?? '').isEmpty ? 'La contrasena actual es obligatoria' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nuevaController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Nueva contrasena'),
                  validator: (value) =>
                      (value ?? '').length < 8 ? 'Minimo 8 caracteres' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _confirmController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Confirmar nueva contrasena'),
                  validator: (value) =>
                      (value ?? '').isEmpty ? 'Confirma la nueva contrasena' : null,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Actualizar contrasena'),
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
