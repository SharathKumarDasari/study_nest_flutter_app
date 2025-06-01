import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Import flutter_dotenv
import 'screens/register_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/year_screen.dart';
import 'screens/subjects_all.dart';
import 'screens/subjects_screen.dart';
import 'screens/about_us_screen.dart';
import 'screens/doubt_session_page.dart';
import 'screens/career_paths_page.dart';
import 'screens/upload_career_path_page.dart';

Future<void> main() async {
  await dotenv.load(fileName: ".env"); // Load the .env file
  runApp(const StudyNestApp());
}

class StudyNestApp extends StatelessWidget {
  const StudyNestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Study Nest',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(),
        '/year': (context) => const YearScreen(),
        '/subjects': (context) => const SubjectsAllScreen(),
        '/about': (context) => const AboutUsScreen(),
        '/doubt': (context) => const DoubtSessionPage(),
        '/career': (context) => const CareerPathsPage(),
        '/upload-career-path': (context) => const UploadCareerPathPage(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/subject') {
          final args = settings.arguments as Map<String, dynamic>?;
          if (args == null || !args.containsKey('subjectName') || args['subjectName'] == null || args['subjectName'].isEmpty) {
            // Redirect to home if subjectName is invalid
            return MaterialPageRoute(builder: (context) => const HomeScreen());
          }
          return MaterialPageRoute(
            builder: (context) => SubjectScreen(subjectName: args['subjectName']),
          );
        }
        return null;
      },
    );
  }
}