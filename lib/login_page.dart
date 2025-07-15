import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  String? _error;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      setState(() {
        _error = 'Por favor corrige los errores del formulario.';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (response.user == null) {
        setState(() {
          _error =
              'Usuario no registrado, regístrese o verifique sus credenciales';
        });
      } else {
        Navigator.pushReplacementNamed(context, '/visitantes');
      }
    } on AuthException catch (e) {
      setState(() {
        if (e.message.toLowerCase().contains('invalid login credentials')) {
          _error =
              'Usuario no registrado, regístrese o verifique sus credenciales';
        } else {
          _error = e.message;
        }
      });
    } catch (e) {
      setState(() {
        _error = 'Error inesperado';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      setState(() {
        _error = 'Por favor corrige los errores del formulario.';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
      );
      if (response.user == null) {
        setState(() {
          _error = 'No se pudo registrar. Verifica los datos.';
        });
      } else {
        setState(() {
          _error = 'Registro exitoso. Revisa tu correo para confirmar.';
        });
      }
    } on AuthException catch (e) {
      setState(() {
        _error = e.message;
      });
    } catch (e) {
      setState(() {
        _error = 'Error inesperado';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = const Color(0xFF2196F3); // Azul claro
    final Color accentColor = const Color(0xFFBBDEFB); // Azul más claro
    final Color buttonColor = const Color(0xFF1976D2); // Azul más fuerte
    return Scaffold(
      backgroundColor: accentColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        title: const Text('Login', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(24.0),
            margin: const EdgeInsets.symmetric(horizontal: 16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.1),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: accentColor,
                    child: const Icon(
                      Icons.person,
                      size: 48,
                      color: Color(0xFF1976D2),
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Correo',
                      prefixIcon: const Icon(
                        Icons.email,
                        color: Color(0xFF1976D2),
                      ),
                      filled: true,
                      fillColor: accentColor.withOpacity(0.3),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'El correo es obligatorio';
                      }
                      // Expresión regular estándar para correos válidos
                      final valueSanitized = value.replaceAll('\u0000', '');
                      final emailPattern = RegExp(
                        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                      );
                      if (!emailPattern.hasMatch(valueSanitized)) {
                        return 'Correo inválido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: const Icon(
                        Icons.lock,
                        color: Color(0xFF1976D2),
                      ),
                      filled: true,
                      fillColor: accentColor.withOpacity(0.3),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'La contraseña es obligatoria';
                      }
                      if (value.length < 6) {
                        return 'Mínimo 6 caracteres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Text(
                        _error!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _loading ? null : _login,
                      icon: const Icon(Icons.login, color: Colors.white),
                      label: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Iniciar sesión',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: buttonColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _loading ? null : _register,
                      icon: const Icon(
                        Icons.person_add,
                        color: Color(0xFF1976D2),
                      ),
                      label: const Text(
                        'Registrarse',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: buttonColor,
                        side: BorderSide(color: buttonColor, width: 2),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(fontSize: 16),
                      ),
                    ),
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
