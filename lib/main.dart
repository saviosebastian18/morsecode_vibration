import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';
import 'package:google_speech/google_speech.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:vibration/vibration.dart';

void main() {
  runApp(const SummarizerApp());
}

class SummarizerApp extends StatelessWidget {
  const SummarizerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Summarizer & Vibration',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("AI Assistive App")),
      body: Center(
        child: ElevatedButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TextSummarizerPage()),
          ),
          child: const Text("Text & Video Summarizer"),
        ),
      ),
    );
  }
}

class TextSummarizerPage extends StatefulWidget {
  const TextSummarizerPage({super.key});

  @override
  State<TextSummarizerPage> createState() => _TextSummarizerPageState();
}

class _TextSummarizerPageState extends State<TextSummarizerPage> {
  final TextEditingController _textController = TextEditingController();
  String _summary = '';
  bool _loading = false;
  final FlutterFFmpeg _ffmpeg = FlutterFFmpeg();

  Future<void> summarizeText(String inputText) async {
    setState(() => _loading = true);
    const apiKey = 'YOUR_GEMINI_API_KEY_HERE';
    const url = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=$apiKey';

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"contents": [{"parts": [{"text": "Summarize the following:\n$inputText"}]}]}),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final text = json['candidates'][0]['content']['parts'][0]['text'];
      setState(() => _summary = text);
    } else {
      setState(() => _summary = 'Failed to summarize');
    }
    setState(() => _loading = false);
  }

  Future<void> pickVideoFile() async {
    var status = await Permission.storage.request();
    if (status.isGranted) {
      FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.video);
      if (result != null) {
        File videoFile = File(result.files.single.path!);
        extractAudio(videoFile);
      }
    }
  }

  Future<void> extractAudio(File videoFile) async {
    String audioPath = videoFile.path.replaceAll('.mp4', '.wav');
    await _ffmpeg.execute('-i ${videoFile.path} -q:a 0 -map a $audioPath');
    transcribeAudio(audioPath);
  }

  Future<void> transcribeAudio(String audioPath) async {
    final speechToText = GoogleSpeechToText();
    String transcribedText = await speechToText.transcribeAudio(audioPath);
    _textController.text = transcribedText;
    summarizeText(transcribedText);
  }

  Future<void> vibrateMorse(String text) async {
    String morse = convertToMorse(text);
    List<int> pattern = [];
    int dot = 200, dash = 600, gap = 200, letterGap = 600, wordGap = 1400, sentenceGap = 2000;

    for (var symbol in morse.split('')) {
      if (symbol == '.') pattern.add(dot);
      else if (symbol == '-') pattern.add(dash);
      else if (symbol == ' ') pattern.add(wordGap);
      pattern.add(gap);
    }

    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(pattern: pattern);
    }
  }

  String convertToMorse(String text) {
    final Map<String, String> morseMap = {
      'A': '.-', 'B': '-...', 'C': '-.-.', 'D': '-..', 'E': '.', 'F': '..-.',
      'G': '--.', 'H': '....', 'I': '..', 'J': '.---', 'K': '-.-', 'L': '.-..',
      'M': '--', 'N': '-.', 'O': '---', 'P': '.--.', 'Q': '--.-', 'R': '.-.',
      'S': '...', 'T': '-', 'U': '..-', 'V': '...-', 'W': '.--', 'X': '-..-',
      'Y': '-.--', 'Z': '--..', ' ': ' '
    };
    return text.toUpperCase().split('').map((char) => morseMap[char] ?? '').join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Summarizer")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _textController,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'Enter text manually',
                border: OutlineInputBorder(),
              ),
            ),
            ElevatedButton(onPressed: pickVideoFile, child: const Text("Upload Video")),
            ElevatedButton(onPressed: _loading ? null : () => summarizeText(_textController.text), child: _loading ? const CircularProgressIndicator() : const Text("Summarize")),
            Text(_summary, style: const TextStyle(fontSize: 16)),
            ElevatedButton(onPressed: () => vibrateMorse(_summary), child: const Text("Translate to Vibration")),
          ],
        ),
      ),
    );
  }
}
