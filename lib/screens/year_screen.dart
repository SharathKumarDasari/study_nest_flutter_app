import 'package:flutter/material.dart';
import 'package:study_nest/services/api_service.dart';
import './login_screen.dart'; // Import to access currentUserRole
class YearScreen extends StatefulWidget {
  const YearScreen({super.key});

  @override
  State<YearScreen> createState() => _YearScreenState();
}

class _YearScreenState extends State<YearScreen> {
  final ApiService apiService = ApiService();
  List<dynamic> subjects = [];
  final TextEditingController _subjectController = TextEditingController();
  late int year;
  late int semesterStart;
  late int semesterEnd;
  late Color semesterColor;

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  void _loadSubjects() async {
    try {
      final fetchedSubjects = await apiService.getSubjects();
      setState(() {
        subjects = fetchedSubjects;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading subjects: $e')));
    }
  }

  void _addSubject(int semester) async {
    // Show dialog to enter subject name
    final subjectName = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Subject'),
          content: TextField(
            controller: _subjectController,
            decoration: const InputDecoration(
              labelText: 'Enter Subject Name',
              hintText: 'e.g., Mathematics',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), // Cancel
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (_subjectController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a subject name')),
                  );
                  return;
                }
                Navigator.pop(context, _subjectController.text); // Return subject name
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );

    if (subjectName == null || subjectName.isEmpty) return; // User canceled or input is empty

    try {
      await apiService.createPage(subjectName, semester);
      _subjectController.clear();
      _loadSubjects();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error adding subject: $e')));
    }
  }

  void _deleteSubject(String subjectName) async {
    try {
      await apiService.deletePage(subjectName);
      _loadSubjects();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting subject: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get the year from route arguments
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    year = args['year'] as int;
    semesterStart = (year * 2) - 1; // e.g., Year 1: Sem 1, Year 2: Sem 3
    semesterEnd = year * 2; // e.g., Year 1: Sem 2, Year 2: Sem 4

    // Set semester color based on year
    switch (year) {
      case 1:
        semesterColor = Colors.yellow.shade100;
        break;
      case 2:
        semesterColor = Colors.orange.shade100;
        break;
      case 3:
        semesterColor = Colors.green.shade100;
        break;
      case 4:
        semesterColor = Colors.blue.shade100;
        break;
      default:
        semesterColor = Colors.grey.shade100;
    }

    final semesterSubjects1 = subjects.where((subject) => subject['semester'] == semesterStart).toList();
    final semesterSubjects2 = subjects.where((subject) => subject['semester'] == semesterEnd).toList();

    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo-on-dark.png',
              height: 40,
              errorBuilder: (context, error, stackTrace) => const Text(
                'Study Nest',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '$year${year == 1 ? 'st' : year == 2 ? 'nd' : year == 3 ? 'rd' : 'th'} Year',
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        backgroundColor: Colors.black,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.black,
              ),
              child: Text(
                'Study Nest',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/home');
              },
            ),
            ListTile(
              leading: const Icon(Icons.book),
              title: const Text('Subjects'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/subjects');
              },
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('About Us'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/about');
              },
            ),
            if (year != 1)
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('First Year'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/year', arguments: {'year': 1});
                },
              ),
            if (year != 2)
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('Second Year'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/year', arguments: {'year': 2});
                },
              ),
            if (year != 3)
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('Third Year'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/year', arguments: {'year': 3});
                },
              ),
            if (year != 4)
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('Fourth Year'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/year', arguments: {'year': 4});
                },
              ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () async {
                // await apiService.logout();
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildSemesterSection(
              context,
              '$semesterStart${semesterStart == 1 ? 'st' : semesterStart == 3 ? 'rd' : 'th'} Sem',
              semesterStart,
              semesterSubjects1,
            ),
            _buildSemesterSection(
              context,
              '$semesterEnd${semesterEnd == 1 ? 'st' : semesterEnd == 3 ? 'rd' : 'th'} Sem',
              semesterEnd,
              semesterSubjects2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSemesterSection(BuildContext context, String title, int semester, List<dynamic> semesterSubjects) {
    return Container(
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: semesterColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          if (currentUserRole == 'teacher') ...[
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => _addSubject(semester),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
              ),
              child: const Text('Add Subject'),
            ),
          ],
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: semesterSubjects.length,
            itemBuilder: (context, index) {
              final subject = semesterSubjects[index];
              return ListTile(
                title: Text(subject['name']),
                trailing: currentUserRole == 'teacher'
                    ? IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteSubject(subject['name']),
                      )
                    : null,
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/subject',
                    arguments: {'subjectName': subject['name']},
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}