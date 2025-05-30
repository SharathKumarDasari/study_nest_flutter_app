import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:study_nest/screens/login_screen.dart'; // For currentUserRole

class CareerPathsPage extends StatelessWidget {
  const CareerPathsPage({super.key});

  // Hardcoded career paths and their PDF URLs (replace with actual server URLs)
  static const Map<String, String> careerPaths = {
    'Frontend Developer': 'https://example.com/frontend-roadmap.pdf',
    'Backend Developer': 'https://example.com/backend-roadmap.pdf',
    'DevOps Engineer': 'https://example.com/devops-roadmap.pdf',
    'Full Stack Developer': 'https://example.com/fullstack-roadmap.pdf',
    'Data Scientist': 'https://example.com/datascience-roadmap.pdf',
  };

  // Function to launch the PDF URL in a browser
  Future<void> _launchPDF(String url, BuildContext context) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the PDF. Please try again later.')),
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
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: careerPaths.length,
        itemBuilder: (context, index) {
          final careerPath = careerPaths.keys.elementAt(index);
          final pdfUrl = careerPaths[careerPath]!;
          return Card(
            elevation: 4.0,
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            child: ListTile(
              leading: const Icon(Icons.work, color: Colors.blue),
              title: Text(
                careerPath,
                style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('Tap to view the roadmap'),
              trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey),
              onTap: () => _launchPDF(pdfUrl, context),
            ),
          );
        },
      ),
    );
  }
}