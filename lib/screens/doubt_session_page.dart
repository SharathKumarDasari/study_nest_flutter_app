import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io'; // For SocketException
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:study_nest/services/api_service.dart';
import 'package:study_nest/screens/login_screen.dart'; // For currentUserRole

class DoubtSessionPage extends StatefulWidget {
  const DoubtSessionPage({super.key});

  @override
  State<DoubtSessionPage> createState() => _DoubtSessionPageState();
}

class _DoubtSessionPageState extends State<DoubtSessionPage> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  final ScrollController _scrollController = ScrollController();
  final ApiService apiService = ApiService();
  final _storage = const FlutterSecureStorage();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeApiKey();
  }

  // Initialize API key in secure storage (run once)
  Future<void> _initializeApiKey() async {
    String? apiKey = await _storage.read(key: 'grok_api_key');
    if (apiKey == null) {
      const String initialApiKey = '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';
      await _storage.write(key: 'grok_api_key', value: initialApiKey);
    }
  }

  // Function to call GroqCloud API with llama3-70b-8192 model
  Future<String> _getChatbotResponse(String query) async {
    try {
      const String apiUrl = 'https://api.grok.x.ai/v1/chat/completions';
      final String? apiKey = await _storage.read(key: 'grok_api_key');

      if (apiKey == null || apiKey.isEmpty) {
        return 'Error: API key not found. Please set up the API key.';
      }

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'llama3-70b-8192',
          'messages': [
            {'role': 'user', 'content': query},
          ],
          'max_tokens': 100,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          if (data['choices'] != null && data['choices'].isNotEmpty) {
            return data['choices'][0]['message']['content']?.trim() ?? 'Sorry, I got a response but it was empty.';
          } else {
            return 'Sorry, I got a response but it was empty.';
          }
        } catch (e) {
          return 'Error: Failed to parse the server response. The response might be malformed.';
        }
      } else if (response.statusCode == 401) {
        return 'Error: Invalid or unauthorized API key. Please verify your Groq API key at https://x.ai/api.';
      } else if (response.statusCode == 429) {
        return 'Rate limit exceeded. Please wait a few minutes and try again.';
      } else if (response.statusCode == 404) {
        return 'Model not found. Please check the model name or refer to https://x.ai/api for supported models.';
      } else {
        return 'Sorry, I couldn\'t connect to the server. Status: ${response.statusCode}';
      }
    } on SocketException {
      return 'Error: No internet connection. Please check your network and try again.';
    } catch (e) {
      return 'Oops, something went wrong: $e';
    }
  }

  void _sendMessage() async {
    if (_controller.text.trim().isEmpty) return;

    String userQuery = _controller.text;
    setState(() {
      _messages.add({'sender': 'user', 'text': userQuery});
      _controller.clear();
      _isLoading = true;
    });

    String botResponse = await _getChatbotResponse(userQuery);

    if (mounted) {
      setState(() {
        _isLoading = false;
        _messages.add({'sender': 'bot', 'text': botResponse});
      });
    }

    if (botResponse.startsWith('Error') || botResponse.startsWith('Sorry')) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(botResponse)));
      }
    }

    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
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
          mainAxisSize: MainAxisSize.min, // Prevent overflow
          children: [
            Image.asset(
              'assets/logo-on-dark.png',
              height: 40
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
                // await apiService.logout();
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
              controller: _scrollController,
              padding: const EdgeInsets.all(8.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                bool isUser = _messages[index]['sender'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.blue[200] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Text(
                      _messages[index]['text']!,
                      style: TextStyle(
                        color: isUser ? Colors.white : Colors.black87,
                        fontSize: 16.0,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Ask your doubt...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8.0),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blue),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}