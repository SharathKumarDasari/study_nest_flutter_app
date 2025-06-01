import 'package:flutter/material.dart';
import 'package:StudyNest/services/api_service.dart';
import 'package:StudyNest/screens/login_screen.dart'; // For currentUserRole
import 'package:file_picker/file_picker.dart';

class UploadCareerPathPage extends StatefulWidget {
  const UploadCareerPathPage({super.key});

  @override
  State<UploadCareerPathPage> createState() => _UploadCareerPathPageState();
}

class _UploadCareerPathPageState extends State<UploadCareerPathPage> {
  final ApiService apiService = ApiService();
  final TextEditingController _careerPathController = TextEditingController();
  String? _filePath;

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result == null || result.files.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No file selected')),
          );
        }
        return;
      }

      final file = result.files.single;
      if (!file.name.toLowerCase().endsWith('.pdf')) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a PDF file')),
          );
        }
        return;
      }

      if (file.path == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('File path not available')),
          );
        }
        return;
      }

      setState(() {
        _filePath = file.path;
      });
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking file: $e')),
        );
      }
    }
  }

  Future<void> _uploadCareerPath() async {
    final careerPath = _careerPathController.text.trim();
    if (careerPath.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a career path name')),
      );
      return;
    }

    if (_filePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a PDF file')),
      );
      return;
    }

    try {
      await apiService.uploadCareerPath(careerPath, _filePath!);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Career path PDF uploaded successfully')),
        );
        _careerPathController.clear();
        setState(() {
          _filePath = null;
        });
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading career path PDF: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () {
              final scaffold = Scaffold.of(context);
              if (scaffold.hasDrawer) {
                scaffold.openDrawer();
              } else {
                debugPrint('Error: No Scaffold with a Drawer found.');
              }
            },
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/logo-on-dark.png',
              height: 40,
              errorBuilder: (context, error, stackTrace) {
                debugPrint('Error loading logo asset: $error');
                return const Text(
                  'Study Nest',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                );
              },
            ),
            // const SizedBox(width: 10),
            // const Text(
            //   'Upload Career Path',
            //   style: TextStyle(color: Colors.white),
            // ),
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
              leading: const Icon(Icons.chat),
              title: const Text('Doubt Session'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/doubt');
              },
            ),
            if (currentUserRole == 'student')
              ListTile(
                leading: const Icon(Icons.work),
                title: const Text('Career Paths'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/career');
                },
              ),
            if (currentUserRole == 'teacher')
              ListTile(
                leading: const Icon(Icons.upload_file),
                title: const Text('Upload Career Path'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/upload-career-path');
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
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () async {
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _careerPathController,
              decoration: const InputDecoration(
                labelText: 'Career Path Name',
                hintText: 'e.g., Frontend Developer',
              ),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _pickFile,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
              ),
              child: const Text('Select PDF File'),
            ),
            const SizedBox(height: 8.0),
            Text(
              _filePath != null ? 'File selected: ${_filePath!.split('/').last}' : 'No file selected',
              style: const TextStyle(fontSize: 16.0),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _uploadCareerPath,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
              ),
              child: const Text('Upload Career Path PDF'),
            ),
          ],
        ),
      ),
    );
  }
}