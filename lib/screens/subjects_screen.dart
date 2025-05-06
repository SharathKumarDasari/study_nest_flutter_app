import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Added for debugPrint
import 'package:study_nest/services/api_service.dart';
import 'package:file_picker/file_picker.dart';
import './login_screen.dart'; // Import to access currentUserRole
import 'dart:convert'; // For base64 decoding
import 'dart:io'; // For File handling
import 'package:path_provider/path_provider.dart'; // For temporary directory
import 'package:open_file/open_file.dart'; // For opening PDFs

class SubjectScreen extends StatefulWidget {
  final String subjectName;

  const SubjectScreen({super.key, required this.subjectName});

  @override
  State<SubjectScreen> createState() => _SubjectScreenState();
}

class _SubjectScreenState extends State<SubjectScreen> {
  final ApiService apiService = ApiService();
  List<Map<String, dynamic>> files = [];

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  void _loadFiles() async {
    try {
      final response = await apiService.getFiles(widget.subjectName);
      debugPrint('Load files response: $response');
      setState(() {
        files = response;
      });
    } catch (e) {
      String errorMessage = 'Failed to load files';
      if (e.toString().contains('<!DOCTYPE html>')) {
        errorMessage = 'Failed to load files: Server returned an HTML error page';
      } else if (e is FormatException) {
        errorMessage = 'Failed to load files: Invalid data format';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$errorMessage ($e)')),
      );
    }
  }

  void _uploadFile() async {
    try {
      // Validate subjectName
      final subjectName = widget.subjectName.trim();
      if (subjectName.isEmpty || !RegExp(r'^[a-zA-Z0-9\s]+$').hasMatch(subjectName)) {
        throw Exception('Invalid subject name: $subjectName');
      }

      // Pick a PDF file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'], // Restrict to PDF files
      );

      if (result == null || result.files.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No file selected')),
        );
        return;
      }

      // Ensure the selected file is a PDF
      final file = result.files.single;
      if (!file.name.toLowerCase().endsWith('.pdf')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a PDF file')),
        );
        return;
      }

      if (file.path == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File path not available')),
        );
        return;
      }

      // Log the subjectName and file details for debugging
      debugPrint('Subject name: $subjectName');
      debugPrint('Uploading file: ${file.name}, Path: ${file.path} for subject: $subjectName');

      // Upload the file
      await apiService.uploadFile(subjectName, file.path!);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File uploaded successfully')),
      );
      _loadFiles(); // Refresh the file list
    } catch (e) {
      String errorMessage = 'Error uploading file';
      if (e.toString().contains('<!DOCTYPE html>')) {
        errorMessage = 'Failed to upload file: Server returned an HTML error page';
      } else if (e is FormatException) {
        errorMessage = 'Failed to upload file: Invalid response format';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$errorMessage: $e')),
      );
      debugPrint('Upload error: $e');
    }
  }

  void _viewFile(Map<String, dynamic> file) async {
    try {
      // Decode base64 file data
      final fileData = base64Decode(file['fileData']);
      final fileName = file['name'];

      // Save to temporary directory
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/$fileName');
      await tempFile.writeAsBytes(fileData);

      // Open the file
      final result = await OpenFile.open(tempFile.path);
      if (result.type != ResultType.done) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open file: ${result.message}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error opening file: $e')),
      );
      debugPrint('Open file error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
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
              'assets/logo-on-dark.png',
              height: 40,
              errorBuilder: (context, error, stackTrace) {
                debugPrint('Failed to load logo: $error');
                return const Text(
                  'Study Nest',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                );
              },
            ),
            const SizedBox(width: 10),
            Text(
              widget.subjectName,
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
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () async {
                await apiService.logout();
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
            if (currentUserRole == 'teacher') // Show upload button only for teachers
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: ElevatedButton(
                  onPressed: _uploadFile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Upload PDF'),
                ),
              ),
            Expanded(
              child: ListView.builder(
                itemCount: files.length,
                itemBuilder: (context, index) {
                  final file = files[index];
                  return ListTile(
                    title: Text(file['name']),
                    leading: const Icon(Icons.picture_as_pdf),
                    onTap: () => _viewFile(file),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}