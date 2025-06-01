import 'package:flutter/material.dart';
import 'package:study_nest/services/api_service.dart';
import 'package:study_nest/screens/login_screen.dart'; // For currentUserRole
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:study_nest/screens/permissions.dart'; // For requesting permissions

class SubjectScreen extends StatefulWidget {
  final String subjectName;

  const SubjectScreen({super.key, required this.subjectName});

  @override
  State<SubjectScreen> createState() => _SubjectScreenState();
}

class _SubjectScreenState extends State<SubjectScreen> {
  final ApiService apiService = ApiService();
  List<Map<String, dynamic>> files = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    try {
      final fetchedFiles = await apiService.getFiles(widget.subjectName);
      setState(() {
        files = fetchedFiles;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load files: $e')),
        );
      }
    }
  }

  Future<void> _uploadFile() async {
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

      await apiService.uploadFile(widget.subjectName, file.path!);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File uploaded successfully')),
        );
        _loadFiles(); // Refresh the file list
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading file: $e')),
        );
      }
    }
  }

  Future<void> _viewFile(Map<String, dynamic> file) async {
    try {
      final fileData = base64Decode(file['fileData']);
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/${file['name']}');
      await tempFile.writeAsBytes(fileData);

      final result = await OpenFile.open(tempFile.path);
      if (result.type != ResultType.done) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to open file: ${result.message}')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening file: $e')),
        );
      }
    }
  }

  Future<void> _downloadPDF(Map<String, dynamic> file) async {
    try {
      // Request storage permission
      final hasPermission = await requestStoragePermission();
      if (!hasPermission) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Storage permission denied. Cannot download PDF.')),
          );
        }
        return;
      }

      // Decode base64 PDF data
      final pdfData = base64Decode(file['fileData']);
      final fileName = file['name'];

      // Get the Downloads directory
      Directory? downloadsDir;
      try {
        downloadsDir = await getDownloadsDirectory();
        if (downloadsDir == null) {
          throw Exception('Downloads directory not found');
        }
      } catch (e) {
        // Fallback to application documents directory if Downloads directory is unavailable
        downloadsDir = await getApplicationDocumentsDirectory();
      }

      // Save the file to the Downloads directory
      final filePath = '${downloadsDir.path}/$fileName';
      final downloadedFile = File(filePath);
      await downloadedFile.writeAsBytes(pdfData);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF downloaded to $filePath')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error downloading PDF: $e')),
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
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (currentUserRole == 'teacher')
                  Padding(
                    padding: const EdgeInsets.all(16.0),
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
                  child: files.isEmpty
                      ? const Center(child: Text('No files available.'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16.0),
                          itemCount: files.length,
                          itemBuilder: (context, index) {
                            final file = files[index];
                            return Card(
                              elevation: 4.0,
                              margin: const EdgeInsets.symmetric(vertical: 8.0),
                              child: ListTile(
                                leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                                title: Text(file['name']),
                                subtitle: const Text('Tap to view the PDF'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.download, color: Colors.green),
                                      onPressed: () => _downloadPDF(file),
                                      tooltip: 'Download PDF',
                                    ),
                                    const Icon(Icons.arrow_forward_ios, color: Colors.grey),
                                  ],
                                ),
                                onTap: () => _viewFile(file),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}