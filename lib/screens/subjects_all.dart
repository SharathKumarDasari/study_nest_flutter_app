import 'package:flutter/material.dart';
import 'package:study_nest/services/api_service.dart';

class SubjectsAllScreen extends StatefulWidget {
  const SubjectsAllScreen({super.key});

  @override
  State<SubjectsAllScreen> createState() => _SubjectsAllScreenState();
}

class _SubjectsAllScreenState extends State<SubjectsAllScreen> {
  final ApiService apiService = ApiService();
  final Map<String, Map<String, dynamic>> yearPages = {
    'year1.png': {'route': '/year', 'arguments': {'year': 1}},
    'year2.png': {'route': '/year', 'arguments': {'year': 2}},
    'year3.png': {'route': '/year', 'arguments': {'year': 3}},
    'year4.png': {'route': '/year', 'arguments': {'year': 4}},
  };

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    for (var image in yearPages.keys) {
      precacheImage(AssetImage('assets/$image'), context);
    }
    precacheImage(const AssetImage('assets/logo-on-dark.png'), context);
  }

  void _navigateToYear(BuildContext context, String image) {
    final pageInfo = yearPages[image];
    if (pageInfo != null) {
      Navigator.pushNamed(context, pageInfo['route']!, arguments: pageInfo['arguments']);
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
              errorBuilder: (context, error, stackTrace) => const Text(
                'Study Nest',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Subjects',
              style: TextStyle(color: Colors.white),
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
                // await apiService.logout();
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ],
        ),
      ),
      body: Container(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          children: yearPages.keys.map((image) {
            return InkWell(
              onTap: () => _navigateToYear(context, image),
              child: Semantics(
                label: 'Navigate to ${image.replaceAll('.png', '')} page',
                child: Image.asset(
                  'assets/$image',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.error),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}