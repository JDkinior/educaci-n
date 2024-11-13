import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'student_page.dart'; // Ventana de estudiante
import 'teacher_page.dart'; // Ventana de profesor

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _role = 'Estudiante';

  bool _isLoginMode = true;

  Future<void> _register() async {
    try {
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'role': _role,
        'email': _emailController.text,
      });

      _navigateToRolePage(_role);
    } catch (e) {
      print('Error al registrar: $e');
    }
  }

  Future<void> _login() async {
    try {
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      final userDoc = await _firestore.collection('users').doc(userCredential.user!.uid).get();
      final role = userDoc['role'];

      _navigateToRolePage(role);
    } catch (e) {
      print('Error al iniciar sesión: $e');
    }
  }

  void _navigateToRolePage(String role) {
    if (role == 'Estudiante') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => StudentPage()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => TeacherPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isLoginMode ? 'Iniciar Sesión' : 'Registro')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Contraseña'),
              obscureText: true,
            ),
            if (!_isLoginMode)
              DropdownButton<String>(
                value: _role,
                items: <String>['Estudiante', 'Profesor'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _role = newValue!;
                  });
                },
              ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoginMode ? _login : _register,
              child: Text(_isLoginMode ? 'Iniciar Sesión' : 'Registrarse'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                setState(() {
                  _isLoginMode = !_isLoginMode;
                });
              },
              child: Text(_isLoginMode
                  ? '¿No tienes cuenta? Créala aquí'
                  : '¿Ya tienes cuenta? Inicia sesión aquí'),
            ),
          ],
        ),
      ),
    );
  }
}
