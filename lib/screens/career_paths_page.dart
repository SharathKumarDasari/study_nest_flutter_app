import 'package:flutter/material.dart';
import 'package:study_nest/services/api_service.dart';
import 'package:study_nest/screens/login_screen.dart'; // For currentUserRole
import 'dart:convert'; // For base64 decoding
import 'dart:io'; // For File handling
import 'package:path_provider/path_provider.dart'; // For temporary directory and downloads
import 'package:open_file/open_file.dart'; // For opening PDFs
import 'package:study_nest/screens/permissions.dart'; // For requesting permissions

class CareerPathsPage extends StatefulWidget {
  const CareerPathsPage({super.key});

  @override
  State<CareerPathsPage> createState() => _CareerPathsPageState();
}

class _CareerPathsPageState extends State<CareerPathsPage> {
  final ApiService apiService = ApiService();
  List<Map<String, dynamic>> careerPaths = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCareerPaths();
  }

  // Fetch career paths from the backend
  void _loadCareerPaths() async {
    try {
      final fetchedCareerPaths = await apiService.getCareerPaths();
      setState(() {
        careerPaths = fetchedCareerPaths;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load career paths: $e')),
        );
      }
    }
  }

  // Function to view the PDF
  Future<void> _viewPDF(Map<String, dynamic> careerPath) async {
    try {
      // Decode base64 PDF data
      final pdfData = base64Decode(careerPath['pdfData']);
      final fileName = '${careerPath['careerPath'].toLowerCase().replaceAll(' ', '_')}_roadmap.pdf';

      // Save to temporary directory
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/$fileName');
      await tempFile.writeAsBytes(pdfData);

      // Open the file
      final result = await OpenFile.open(tempFile.path);
      if (result.type != ResultType.done) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to open PDF: ${result.message}')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening PDF: $e')),
        );
      }
    }
  }

  // Function to download the PDF
  Future<void> _downloadPDF(Map<String, dynamic> careerPath) async {
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
      final pdfData = base64Decode(careerPath['pdfData']);
      final fileName = '${careerPath['careerPath'].toLowerCase().replaceAll(' ', '_')}_roadmap.pdf';

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
      final file = File(filePath);
      await file.writeAsBytes(pdfData);

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
            // const SizedBox(width: 10),
            // const Text(
            //   'Career Paths',
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
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : careerPaths.isEmpty
              ? const Center(child: Text('No career paths available.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: careerPaths.length,
                  itemBuilder: (context, index) {
                    final careerPath = careerPaths[index];
                    return Card(
                      elevation: 4.0,
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      child: ListTile(
                        leading: const Icon(Icons.work, color: Colors.blue),
                        title: Text(
                          careerPath['careerPath'],
                          style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                        ),
                        subtitle: const Text('Tap to view the roadmap'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.download, color: Colors.green),
                              onPressed: () => _downloadPDF(careerPath),
                              tooltip: 'Download PDF',
                            ),
                            const Icon(Icons.arrow_forward_ios, color: Colors.grey),
                          ],
                        ),
                        onTap: () => _viewPDF(careerPath),
                      ),
                    );
                  },
                ),
    );
  }
}