import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';

void main() {
  runApp(const MorseVibrationApp());
}

class MorseVibrationApp extends StatelessWidget {
  const MorseVibrationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Morse Code Vibration',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light().copyWith(
        primaryColor: Colors.blueAccent,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const MorseCodeScreen(),
    );
  }
}

class MorseCodeScreen extends StatefulWidget {
  const MorseCodeScreen({super.key});

  @override
  State<MorseCodeScreen> createState() => _MorseCodeScreenState();
}

class _MorseCodeScreenState extends State<MorseCodeScreen> {
  final TextEditingController _textController = TextEditingController();
  final Map<String, String> morseMap = {
    'A': '.-', 'B': '-...', 'C': '-.-.', 'D': '-..', 'E': '.', 'F': '..-.',
    'G': '--.', 'H': '....', 'I': '..', 'J': '.---', 'K': '-.-', 'L': '.-..',
    'M': '--', 'N': '-.', 'O': '---', 'P': '.--.', 'Q': '--.-', 'R': '.-.',
    'S': '...', 'T': '-', 'U': '..-', 'V': '...-', 'W': '.--', 'X': '-..-',
    'Y': '-.--', 'Z': '--..', '1': '.----', '2': '..---', '3': '...--',
    '4': '....-', '5': '.....', '6': '-....', '7': '--...', '8': '---..',
    '9': '----.', '0': '-----', ' ': ' '  // Space between words
  };

  /// Converts text to Morse code
  String convertToMorse(String text) {
    return text.toUpperCase().split('').map((char) {
      return morseMap[char] ?? '';
    }).join(' ');
  }

  /// Vibrates based on Morse Code pattern
  Future<void> vibrateMorse(String morse) async {
    List<int> pattern = [];
    int dotDuration = 200;  // Duration of a dot
    int dashDuration = 600; // Duration of a dash
    int gapBetweenSymbols = 200;
    int spaceBetweenLetters = 400;

    for (var symbol in morse.split('')) {
      if (symbol == '.') {
        pattern.add(dotDuration);
      } else if (symbol == '-') {
        pattern.add(dashDuration);
      }
      pattern.add(gapBetweenSymbols); // Gap after dot/dash
    }

    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(pattern: pattern);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Morse Code Vibration"),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Enter text to convert into Morse Code and feel vibrations:",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _textController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Enter text",
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                String morseCode = convertToMorse(_textController.text);
                vibrateMorse(morseCode);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Vibrating Morse: $morseCode")),
                );
              },
              child: const Text("Convert & Vibrate"),
            ),
          ],
        ),
      ),
    );
  }
}
