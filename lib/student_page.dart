import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentPage extends StatefulWidget {
  @override
  _StudentPageState createState() => _StudentPageState();
}

class _StudentPageState extends State<StudentPage> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final TextEditingController studentIdController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController searchController = TextEditingController();

  List<Map<String, dynamic>> students = [];
  List<Map<String, dynamic>> courses = [];
  List<Map<String, dynamic>> professors = [];
  List<String> selectedCourses = [];
  String searchResult = '';

  @override
  void initState() {
    super.initState();
    _loadStudents();
    _loadCourses();
    _loadProfessors();
  }

  Future<void> _loadStudents() async {
    try {
      final snapshot = await firestore.collection('estudiantes').get();
      setState(() {
        students = snapshot.docs.map((doc) {
          return {'id': doc.id, ...doc.data() as Map<String, dynamic>};
        }).toList();
      });
    } catch (e) {
      print('Error loading students: $e');
    }
  }

  Future<void> _loadCourses() async {
    try {
      final snapshot = await firestore.collection('cursos').get();
      setState(() {
        courses = snapshot.docs.map((doc) {
          return {'id': doc.id, ...doc.data() as Map<String, dynamic>};
        }).toList();
      });
    } catch (e) {
      print('Error loading courses: $e');
    }
  }

  Future<void> _loadProfessors() async {
    try {
      final snapshot = await firestore.collection('profesores').get();
      setState(() {
        professors = snapshot.docs.map((doc) {
          return {'id': doc.id, ...doc.data() as Map<String, dynamic>};
        }).toList();
      });
    } catch (e) {
      print('Error loading professors: $e');
    }
  }

  void _addStudent() {
    if (studentIdController.text.isEmpty ||
        nameController.text.isEmpty ||
        lastNameController.text.isEmpty ||
        emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor completa todos los campos')));
      return;
    }

    final newStudent = {
      'documentoId': studentIdController.text,
      'nombre': nameController.text,
      'apellido': lastNameController.text,
      'email': emailController.text,
      'cursos': selectedCourses,
    };

    firestore.collection('estudiantes').add(newStudent).then((_) {
      _loadStudents();
      selectedCourses.clear();
    });
  }

  void _deleteStudent(String studentId) async {
    try {
      await firestore.collection('estudiantes').doc(studentId).delete();
      _loadStudents();
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Estudiante eliminado exitosamente')));
    } catch (e) {
      print('Error deleting student: $e');
    }
  }

  String _getProfessorName(String professorId) {
    final professor = professors.firstWhere(
        (professor) => professor['id'] == professorId,
        orElse: () => {'nombre': 'Desconocido'});
    return professor['nombre'];
  }

  void _enrollInCourse(String studentId, String courseId) async {
    try {
      final courseRef = firestore.collection('cursos').doc(courseId);
      final courseSnapshot = await courseRef.get();

      if (courseSnapshot.exists) {
        final courseData = courseSnapshot.data() as Map<String, dynamic>;
        final enrolledStudents = List<String>.from(courseData['estudiantes'] ?? []);

        enrolledStudents.add(studentId);
        await courseRef.update({'estudiantes': enrolledStudents});

        final studentRef = firestore.collection('estudiantes').doc(studentId);
        final studentSnapshot = await studentRef.get();

        if (studentSnapshot.exists) {
          final studentData = studentSnapshot.data() as Map<String, dynamic>;
          final studentCourses = List<String>.from(studentData['cursos'] ?? []);
          studentCourses.add(courseId);
          await studentRef.update({'cursos': studentCourses});

          await _loadStudents();
          await _loadCourses();
        }
      }
    } catch (e) {
      print('Error enrolling in course: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestión de Estudiantes')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text('DATOS DE ESTUDIANTES', style: TextStyle(fontWeight: FontWeight.bold)),
          TextField(controller: studentIdController, decoration: const InputDecoration(labelText: 'Documento de identidad')),
          TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nombre')),
          TextField(controller: lastNameController, decoration: const InputDecoration(labelText: 'Apellido')),
          TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),

          ElevatedButton(onPressed: _addStudent, child: const Text('Añadir Estudiante')),

          const Divider(),

          const Text('LISTA DE ESTUDIANTES', style: TextStyle(fontWeight: FontWeight.bold)),
          ...students.map((student) => ListTile(
                title: Text('${student['nombre']} ${student['apellido']}'),
                subtitle: Text('Email: ${student['email']}'),
                trailing: PopupMenuButton<String>(
                  onSelected: (courseId) => _enrollInCourse(student['id'], courseId),
                  itemBuilder: (context) => courses.map((course) {
                    return PopupMenuItem<String>(
                      value: course['id'],
                      child: Text(course['nombre']),
                    );
                  }).toList(),
                ),
                leading: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteStudent(student['id']),
                ),
              )),

          const Divider(),

          const Text('BUSCAR ESTUDIANTES', style: TextStyle(fontWeight: FontWeight.bold)),
          TextField(controller: searchController, decoration: const InputDecoration(labelText: 'Buscar por ID o Nombre')),

          ElevatedButton(
            onPressed: () {
              final searchQuery = searchController.text.toLowerCase();
              final foundStudent = students.firstWhere(
                (student) =>
                    student['documentoId'].toString().toLowerCase() == searchQuery ||
                    student['nombre'].toString().toLowerCase().contains(searchQuery) ||
                    student['apellido'].toString().toLowerCase().contains(searchQuery),
                orElse: () => {},
              );

              setState(() {
                searchResult = foundStudent.isNotEmpty
                    ? 'Estudiante encontrado: ${foundStudent['nombre']} ${foundStudent['apellido']}'
                    : 'Estudiante no encontrado';
              });
            },
            child: const Text('Buscar'),
          ),

          Text(searchResult),

          const Divider(),

          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CourseDetailPage(
                    courses: courses,
                    students: students,
                    professors: professors,
                  ),
                ),
              );
            },
            child: const Text('Ver Materias y Estudiantes'),
          ),
        ],
      ),
    );
  }
}

class CourseDetailPage extends StatelessWidget {
  final List<Map<String, dynamic>> courses;
  final List<Map<String, dynamic>> students;
  final List<Map<String, dynamic>> professors;

  CourseDetailPage({required this.courses, required this.students, required this.professors});

  String _getProfessorName(String professorId) {
    final professor = professors.firstWhere(
        (professor) => professor['id'] == professorId,
        orElse: () => {'nombre': 'Desconocido'});
    return professor['nombre'];
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalles de Materias')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: courses.map((course) {
          final enrolledStudentIds = List<String>.from(course['estudiantes'] ?? []);
          final enrolledStudents = students.where((student) => enrolledStudentIds.contains(student['id'])).toList();
          final professorName = _getProfessorName(course['profesor']);

          return Card(
            child: ListTile(
              title: Text(course['nombre']),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Profesor: $professorName'),
                  const Text('Estudiantes:'),
                  ...enrolledStudents.map((student) {
                    return Text('${student['nombre']} ${student['apellido']}');
                  }),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
