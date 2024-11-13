import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'cursos_page.dart'; // Asegúrate de que la ruta es correcta.

class TeacherPage extends StatefulWidget {
  @override
  _TeacherPageState createState() => _TeacherPageState();
}

class _TeacherPageState extends State<TeacherPage> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final TextEditingController docIdController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController searchController = TextEditingController();
  List<Map<String, dynamic>> teachers = [];
  String searchResult = '';

  @override
  void initState() {
    super.initState();
    _loadTeachers();
  }

  Future<void> _loadTeachers() async {
    try {
      final snapshot = await firestore.collection('profesores').get();
      setState(() {
        teachers = snapshot.docs.map((doc) {
          return {'id': doc.id, ...doc.data() as Map<String, dynamic>};
        }).toList();
      });
    } catch (e) {
      print('Error loading teachers: $e');
    }
  }

  void _addTeacher() async {
    if (docIdController.text.isEmpty ||
        nameController.text.isEmpty ||
        lastNameController.text.isEmpty ||
        emailController.text.isEmpty ||
        phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor completa todos los campos')));
      return;
    }

    final newTeacher = {
      'documentoId': docIdController.text,
      'nombre': nameController.text,
      'apellido': lastNameController.text,
      'email': emailController.text,
      'telefono': phoneController.text,
    };

    await firestore.collection('profesores').add(newTeacher);
    _loadTeachers();
  }

  void _modifyTeacher(String id) async {
    final updatedTeacher = {
      'documentoId': docIdController.text,
      'nombre': nameController.text,
      'apellido': lastNameController.text,
      'email': emailController.text,
      'telefono': phoneController.text,
    };
    
    await firestore.collection('profesores').doc(id).update(updatedTeacher);
    _loadTeachers();
  }

  void _searchTeacher() {
    final searchQuery = searchController.text.toLowerCase();
    final foundTeacher = teachers.firstWhere(
      (teacher) =>
          teacher['documentoId'].toString().toLowerCase() == searchQuery ||
          teacher['nombre'].toString().toLowerCase().contains(searchQuery) ||
          teacher['apellido'].toString().toLowerCase().contains(searchQuery),
      orElse: () => {},
    );

    setState(() {
      searchResult = foundTeacher.isNotEmpty
          ? 'Profesor encontrado: ${foundTeacher['nombre']} ${foundTeacher['apellido']}'
          : 'Profesor no encontrado';
    });
  }

  void _deleteTeacher(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: const Text('¿Estás seguro de que quieres eliminar este profesor?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              await firestore.collection('profesores').doc(id).delete();
              Navigator.pop(context);
              _loadTeachers();
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestión de Profesores')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CursoPage()),
              );
            },
            child: const Text('Ir a Gestión de Cursos'),
          ),
          const Text('DATOS DE PROFESORES', style: TextStyle(fontWeight: FontWeight.bold)),
          TextField(controller: docIdController, decoration: const InputDecoration(labelText: 'Documento de identidad')),
          TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nombre')),
          TextField(controller: lastNameController, decoration: const InputDecoration(labelText: 'Apellido')),
          TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
          TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Teléfono')),
          ElevatedButton(onPressed: _addTeacher, child: const Text('Añadir Profesor')),

          const Divider(),

          const Text('LISTA DE PROFESORES', style: TextStyle(fontWeight: FontWeight.bold)),
          ...teachers.map((teacher) => ListTile(
                title: Text('${teacher['nombre']} ${teacher['apellido']}'),
                subtitle: Text('Email: ${teacher['email']}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        docIdController.text = teacher['documentoId'] ?? '';
                        nameController.text = teacher['nombre'] ?? '';
                        lastNameController.text = teacher['apellido'] ?? '';
                        emailController.text = teacher['email'] ?? '';
                        phoneController.text = teacher['telefono'] ?? '';
                        _modifyTeacher(teacher['id']);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _deleteTeacher(teacher['id']),
                    ),
                  ],
                ),
              )),

          const Divider(),

          const Text('BUSCAR PROFESORES', style: TextStyle(fontWeight: FontWeight.bold)),
          TextField(controller: searchController, decoration: const InputDecoration(labelText: 'Buscar por ID o Nombre')),
          ElevatedButton(onPressed: _searchTeacher, child: const Text('Buscar')),
          Text(searchResult),
        ],
      ),
    );
  }
}
