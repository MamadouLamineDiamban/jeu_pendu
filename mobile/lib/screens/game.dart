import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class GameScreen extends StatefulWidget {
  const GameScreen({Key? key}) : super(key: key);

  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  String maskedWord = "";
  int attemptsLeft = 0;
  String status = "";
  final TextEditingController _letterController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _startGame();
  }

  Future<void> _startGame() async {
    const String apiUrl = 'http://127.0.0.1:5000/start'; // Remplacez par l'URL de votre API
    try {
      final response = await http.get(Uri.parse('$apiUrl?level=EASY'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          maskedWord = data['word_state'];
          attemptsLeft = data['attempts_left'];
          status = "ongoing";
        });
      } else {
        _showError("Failed to start game: ${response.body}");
      }
    } catch (e) {
      _showError("An error occurred: $e");
    }
  }

  Future<void> _guessLetter(String letter) async {
    const String apiUrl = 'http://127.0.0.1:5000/guess'; // Remplacez par l'URL de votre API
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'letter': letter}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          maskedWord = data['word_state'];
          attemptsLeft = data['attempts_left'];
          status = data['status'];
        });

        if (status == "win" || status == "lose") {
          _showEndGameDialog();
        }
      } else {
        _showError("Invalid response: ${response.body}");
      }
    } catch (e) {
      _showError("An error occurred: $e");
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Error"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _showEndGameDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(status == "win" ? "Congratulations!" : "Game Over"),
        content: Text(
          status == "win"
              ? "You guessed the word: $maskedWord"
              : "You ran out of attempts. The word was: $maskedWord",
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _startGame();
            },
            child: const Text("Play Again"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Exit"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Hangman Game")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Attempts Left: $attemptsLeft",
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 20),
            Text(
              maskedWord,
              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            if (status == "ongoing")
              TextField(
                controller: _letterController,
                decoration: const InputDecoration(
                  labelText: "Enter a letter",
                  border: OutlineInputBorder(),
                ),
                maxLength: 1,
                onSubmitted: (value) {
                  if (value.isNotEmpty) {
                    _guessLetter(value);
                    _letterController.clear();
                  }
                },
              ),
          ],
        ),
      ),
    );
  }
}
