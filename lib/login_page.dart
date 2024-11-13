import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'student_page.dart';  // Ventana de estudiante
import 'teacher_page.dart';  // Ventana de profesor

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
      appBar: AppBar(title: Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Contraseña'),
              obscureText: true,
            ),
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
            ElevatedButton(
              onPressed: _register,
              child: Text('Registrarse'),
            ),
            ElevatedButton(
              onPressed: _login,
              child: Text('Iniciar Sesión'),
            ),
          ],
        ),
      ),
    );
  }
}
