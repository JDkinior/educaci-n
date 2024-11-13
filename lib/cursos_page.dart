import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CursoPage extends StatefulWidget {
  @override
  _CursoPageState createState() => _CursoPageState();
}

class _CursoPageState extends State<CursoPage> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController studentsCountController = TextEditingController();
  final TextEditingController searchController = TextEditingController();
  String? selectedTeacher;
  List<Map<String, dynamic>> courses = [];
  List<Map<String, dynamic>> teachers = [];
  String searchResult = '';

  @override
  void initState() {
    super.initState();
    _loadTeachers();
    _loadCourses();
  }

  Future<void> _loadTeachers() async {
    final teachersSnapshot = await firestore.collection('profesores').get();
    setState(() {
      teachers = teachersSnapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();
    });
  }

  Future<void> _loadCourses() async {
    final coursesSnapshot = await firestore.collection('cursos').get();
    setState(() {
      courses = coursesSnapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();
    });
  }

  Future<void> _addCourse() async {
    final newCourse = {
      'nombre': nameController.text,
      'cantidadEstudiantes': int.tryParse(studentsCountController.text) ?? 0,
      'profesor': selectedTeacher,
    };
    await firestore.collection('cursos').add(newCourse);
    _loadCourses();
  }

  Future<void> _modifyCourse(String id) async {
    final updatedCourse = {
      'nombre': nameController.text,
      'cantidadEstudiantes': int.tryParse(studentsCountController.text) ?? 0,
      'profesor': selectedTeacher,
    };
    await firestore.collection('cursos').doc(id).update(updatedCourse);
    _loadCourses();
  }

  Future<void> _searchCourse() async {
    final searchQuery = searchController.text.toLowerCase();
    final foundCourse = courses.firstWhere(
      (course) =>
          course['id'].toString().toLowerCase() == searchQuery ||
          course['nombre'].toString().toLowerCase().contains(searchQuery),
      orElse: () => {},
    );
    setState(() {
      searchResult = foundCourse.isNotEmpty
          ? 'Curso encontrado: ${foundCourse['nombre']}'
          : 'Curso no encontrado';
    });
  }

  Future<void> _deleteCourse(String id) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: const Text('¿Estás seguro de que quieres eliminar este curso?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              await firestore.collection('cursos').doc(id).delete();
              Navigator.pop(context);
              _loadCourses();
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
      appBar: AppBar(title: const Text('Gestión de Cursos')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text('AGREGAR CURSO', style: TextStyle(fontWeight: FontWeight.bold)),
          TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nombre')),
          TextField(
            controller: studentsCountController,
            decoration: const InputDecoration(labelText: 'Cantidad de estudiantes'),
            keyboardType: TextInputType.number,
          ),
          DropdownButton<String>(
            value: selectedTeacher,
            hint: const Text('Profesor'),
            items: teachers.map((teacher) {
              return DropdownMenuItem<String>(
                value: teacher['id'].toString(),
                child: Text('${teacher['nombre']} ${teacher['apellido']}'),
              );
            }).toList(),
            onChanged: (newValue) => setState(() => selectedTeacher = newValue),
          ),
          ElevatedButton(onPressed: _addCourse, child: const Text('Añadir Curso')),
          const Divider(),
          const Text('LISTA DE CURSOS', style: TextStyle(fontWeight: FontWeight.bold)),
          ...courses.map((course) => ListTile(
                title: Text(course['nombre']),
                subtitle: Text('Cantidad de estudiantes: ${course['cantidadEstudiantes']}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        nameController.text = course['nombre'] ?? '';
                        studentsCountController.text = course['cantidadEstudiantes'].toString();
                        selectedTeacher = course['profesor'];
                        _modifyCourse(course['id']);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _deleteCourse(course['id']),
                    ),
                  ],
                ),
              )),
          const Divider(),
          const Text('BUSCAR CURSO', style: TextStyle(fontWeight: FontWeight.bold)),
          TextField(controller: searchController, decoration: const InputDecoration(labelText: 'Buscar por ID o Nombre')),
          ElevatedButton(onPressed: _searchCourse, child: const Text('Buscar')),
          Text(searchResult),
        ],
      ),
    );
  }
}
