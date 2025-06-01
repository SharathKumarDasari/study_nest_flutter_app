import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Import flutter_dotenv
import 'package:study_nest/screens/login_screen.dart'; // For currentUserRole
import 'package:http/http.dart' as http;
import 'dart:convert';

class DoubtSessionPage extends StatefulWidget {
  const DoubtSessionPage({super.key});

  @override
  State<DoubtSessionPage> createState() => _DoubtSessionPageState();
}

class _DoubtSessionPageState extends State<DoubtSessionPage> {
  final TextEditingController _controller = TextEditingController();
  List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  // Retrieve the API key from the .env file
  final String apiKey = dotenv.env['API_KEY'] ?? 'default-api-key-if-not-found';

  Future<void> _sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    setState(() {
      _messages.add({'sender': 'user', 'text': message});
      _isLoading = true;
    });

    try {
      // Example: Sending a request to a chatbot API (e.g., Grok API)
      final response = await http.post(
        Uri.parse('https://api.x.ai/v1/chat/completions'), // Replace with actual API endpoint
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'grok', // Replace with the appropriate model
          'messages': [
            {'role': 'user', 'content': message}
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final botMessage = data['choices'][0]['message']['content'];
        setState(() {
          _messages.add({'sender': 'bot', 'text': botMessage});
        });
      } else {
        setState(() {
          _messages.add({'sender': 'bot', 'text': 'Error: Failed to get response from API'});
        });
      }
    } catch (e) {
      setState(() {
        _messages.add({'sender': 'bot', 'text': 'Error: $e'});
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
      _controller.clear();
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
            //   'Doubt Session',
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
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isUser = message['sender'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4.0),
                    padding: const EdgeInsets.all(10.0),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.blue[100] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: Text(message['text']!),
                  ),
                );
              },
            ),
          ),
          if (_isLoading) const CircularProgressIndicator(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Ask your doubt...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: _sendMessage,
                  ),
                ),
                const SizedBox(width: 8.0),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () => _sendMessage(_controller.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}