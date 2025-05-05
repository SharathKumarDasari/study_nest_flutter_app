import 'package:flutter/material.dart';
import 'package:study_nest/services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ApiService apiService = ApiService();

    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text(
          'About Us',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Learn more about our mission',
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            const Text(
              'Study Nest Hub',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Welcome to Study Nest, your ultimate educational companion! At Study Nest, we provide a robust platform designed to support both students and educators. Here, you can effortlessly upload and access lecture notes, PDFs, and a wide range of subject-related files.\n\n'
              'Our smart chat bot is available around the clock to assist you with any queries, ensuring you never feel stuck. Additionally, we offer comprehensive career paths, meticulously curated to help you navigate and achieve your professional goals. Join Study Nest today and elevate your learning experience to new heights!',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.justify,
            ),
            const SizedBox(height: 20),
            Image.asset(
              'assets/pic01.webp',
              height: 200,
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.error),
            ),
            const SizedBox(height: 30),
            const Text(
              'Key Features of Study Nest',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const FeatureItem(
              title: 'Effortless File Uploads and Access',
              description: 'Easily upload and access lecture notes, PDFs, and a variety of subject-related files.',
            ),
            const FeatureItem(
              title: '24/7 Smart Chat Bot',
              description: 'Get round-the-clock assistance with any queries, ensuring you have support whenever you need it.',
            ),
            const FeatureItem(
              title: 'Comprehensive Career Paths',
              description: 'Navigate and achieve your professional goals with meticulously curated career paths.',
            ),
            const FeatureItem(
              title: 'Support for Educators and Students',
              description: 'A platform designed to cater to the needs of both educators and students, enhancing the learning experience.',
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/home');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
              ),
              child: const Text('Back To Home'),
            ),
            const SizedBox(height: 30),
            const Divider(),
            const ContactSection(),
          ],
        ),
      ),
    );
  }
}

class FeatureItem extends StatelessWidget {
  final String title;
  final String description;

  const FeatureItem({super.key, required this.title, required this.description});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.check_circle_outline, color: Colors.green),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(description),
    );
  }
}

class ContactSection extends StatelessWidget {
  const ContactSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'Contact Us',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        const ListTile(
          leading: Icon(Icons.location_on),
          title: Text('Address'),
          subtitle: Text('3-5-1026, Hari Vihar Colony, Bhawani Nagar, Narayanguda, Hyderabad, Telangana 500029'),
        ),
        ListTile(
          leading: const Icon(Icons.phone),
          title: const Text('Phone'),
          subtitle: const Text('+91 12345054321'),
          onTap: () => launchUrl(Uri.parse('tel:+9112345054321')),
        ),
        ListTile(
          leading: const Icon(Icons.email),
          title: const Text('Email'),
          subtitle: const Text('study@studynest.in'),
          onTap: () => launchUrl(Uri.parse('mailto:study@studynest.in')),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: () => launchUrl(Uri.parse('https://www.google.com')),
              icon: const Icon(Icons.g_mobiledata, size: 30),
            ),
            IconButton(
              onPressed: () => launchUrl(Uri.parse('https://www.facebook.com')),
              icon: const Icon(Icons.facebook, size: 30),
            ),
            IconButton(
              onPressed: () => launchUrl(Uri.parse('https://www.instagram.com')),
              icon: const Icon(Icons.camera_alt, size: 30),
            ),
            IconButton(
              onPressed: () => launchUrl(Uri.parse('https://www.linkedin.com')),
              icon: const Icon(Icons.business, size: 30),
            ),
          ],
        ),
      ],
    );
  }
}