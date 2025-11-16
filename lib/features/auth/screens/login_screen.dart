// lib/features/auth/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../theme/app_theme.dart';
import '../auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  bool _isLogin = true;

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final accent = AppTheme.adaptiveAccent(context);
    final textColor = AppTheme.adaptiveText(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isLogin ? "Login" : "Create Account"),
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 16),
            Icon(Icons.lock_outline_rounded, size: 80, color: accent),
            const SizedBox(height: 16),

            Text(
              _isLogin ? "Welcome back!" : "Create your SpeedMath Pro account.",
              style: TextStyle(fontSize: 16, color: textColor.withOpacity(0.8)),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 30),

            // ------------------------------------------------------------
            // 📝 FORM
            // ------------------------------------------------------------
            Form(
              key: _formKey,
              child: Column(
                children: [
                  if (!_isLogin) ...[
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(labelText: "Full Name"),
                      validator: (v) => (!_isLogin && (v == null || v.isEmpty))
                          ? "Enter your name"
                          : null,
                    ),
                    const SizedBox(height: 16),
                  ],

                  TextFormField(
                    controller: _emailCtrl,
                    decoration: const InputDecoration(labelText: "Email"),
                    validator: (v) {
                      if (v == null || v.isEmpty) return "Enter email";
                      if (!v.contains("@")) return "Invalid email";
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _passCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: "Password"),
                    validator: (v) => (v == null || v.length < 6)
                        ? "Minimum 6 characters"
                        : null,
                  ),

                  const SizedBox(height: 12),

                  if (auth.error != null)
                    Text(
                      auth.error!,
                      style: const TextStyle(color: Colors.red),
                    ),

                  const SizedBox(height: 15),

                  // ------------------------------------------------------------
                  // 🔘 LOGIN / REGISTER BUTTON
                  // ------------------------------------------------------------
                  ElevatedButton(
                    onPressed: auth.loading
                        ? null
                        : () async {
                            if (!_formKey.currentState!.validate()) return;

                            if (_isLogin) {
                              await auth.login(
                                _emailCtrl.text.trim(),
                                _passCtrl.text.trim(),
                                context, // 🔥 REQUIRED
                              );
                            } else {
                              await auth.register(
                                _nameCtrl.text.trim(),
                                _emailCtrl.text.trim(),
                                _passCtrl.text.trim(),
                                context, // 🔥 REQUIRED
                              );
                            }

                            if (mounted && auth.error == null) {
                              Navigator.pop(context);
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: auth.loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            _isLogin ? "Login" : "Register",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                  ),

                  const SizedBox(height: 14),

                  TextButton(
                    onPressed: () => setState(() => _isLogin = !_isLogin),
                    child: Text(
                      _isLogin
                          ? "Don't have an account? Register"
                          : "Already registered? Login",
                      style: TextStyle(color: accent),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // ------------------------------------------------------------
            // 🔵 Google Login
            // ------------------------------------------------------------
            OutlinedButton.icon(
              onPressed: () async {
                await auth.loginWithGoogle(context); // 🔥 UPDATED
                if (mounted && auth.error == null) Navigator.pop(context);
              },
              icon: Image.asset('assets/images/google_logo.png', height: 24),
              label: const Text("Continue with Google"),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
