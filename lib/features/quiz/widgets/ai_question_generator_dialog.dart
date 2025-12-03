import 'package:flutter/material.dart';
import 'dart:convert';
import '../../../core/services/gemini_service.dart';
import '../../../core/services/api_service.dart';

class AIQuestionGeneratorDialog extends StatefulWidget {
  final String courseId;

  const AIQuestionGeneratorDialog({super.key, required this. courseId});

  @override
  State<AIQuestionGeneratorDialog> createState() => _AIQuestionGeneratorDialogState();
}

class _AIQuestionGeneratorDialogState extends State<AIQuestionGeneratorDialog> {
  final TextEditingController _materialController = TextEditingController();
  final TextEditingController _easyController = TextEditingController(text: '3');
  final TextEditingController _mediumController = TextEditingController(text: '4');
  final TextEditingController _hardController = TextEditingController(text: '3');
  
  bool _isGenerating = false;
  String _status = '';

  @override
  void dispose() {
    _materialController. dispose();
    _easyController.dispose();
    _mediumController.dispose();
    _hardController.dispose();
    super. dispose();
  }

  Future<void> _generateQuestions() async {
    if (_materialController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide material content')),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
      _status = 'Generating questions with AI...';
    });

    try {
      final geminiService = GeminiService();
      final apiService = ApiService();
      
      final easyCount = int.tryParse(_easyController.text) ?? 0;
      final mediumCount = int.tryParse(_mediumController.text) ?? 0;
      final hardCount = int. tryParse(_hardController.text) ?? 0;

      // Generate questions
      final questions = await geminiService.generateQuizQuestions(
        materialContent: _materialController.text,
        easyCount: easyCount,
        mediumCount: mediumCount,
        hardCount: hardCount,
      );

      setState(() => _status = 'Validating questions...');

      // Validate
      final isValid = geminiService.validateQuestions(
        questions,
        expectedEasy: easyCount,
        expectedMedium: mediumCount,
        expectedHard: hardCount,
      );

      if (! isValid) {
        throw Exception('Generated questions failed validation');
      }

      setState(() => _status = 'Saving to question bank...');

      // Save to Firestore
      for (var question in questions) {
        await apiService.createQuestion(widget.courseId, question);
      }

      setState(() {
        _isGenerating = false;
        _status = '';
      });

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Generated ${questions.length} questions successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }

    } catch (e) {
      setState(() {
        _isGenerating = false;
        _status = '';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors. red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.auto_awesome, color: Colors.purple),
          SizedBox(width: 8),
          Text('AI Question Generator'),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Paste your learning material below and AI will generate quiz questions:',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _materialController,
                maxLines: 8,
                decoration: const InputDecoration(
                  labelText: 'Learning Material',
                  hintText: 'Paste text from lectures, notes, or documents.. .',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                enabled: !_isGenerating,
              ),
              const SizedBox(height: 16),

              const Text(
                'Question Distribution:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _easyController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Easy',
                        border: OutlineInputBorder(),
                      ),
                      enabled: !_isGenerating,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _mediumController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Medium',
                        border: OutlineInputBorder(),
                      ),
                      enabled: ! _isGenerating,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _hardController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Hard',
                        border: OutlineInputBorder(),
                      ),
                      enabled: !_isGenerating,
                    ),
                  ),
                ],
              ),

              if (_isGenerating) ...[
                const SizedBox(height: 16),
                const LinearProgressIndicator(),
                const SizedBox(height: 8),
                Text(
                  _status,
                  style: const TextStyle(fontSize: 14, color: Colors. blue),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isGenerating ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton. icon(
          onPressed: _isGenerating ? null : _generateQuestions,
          icon: const Icon(Icons.auto_awesome),
          label: Text(_isGenerating ? 'Generating...' : 'Generate'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}