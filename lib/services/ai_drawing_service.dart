import 'dart:async';
import 'dart:math';

class AIDrawingResult {
  final String imageUrl;
  final String prompt;

  AIDrawingResult({required this.imageUrl, required this.prompt});
}

class AiDrawingService {
  // In a real application, this would call the Hugging Face API
  // or another service to generate doodle-like drawings
  // For our frontend mockup, we'll simulate this with predefined images

  final List<String> _placeholderImages = [
    'https://via.placeholder.com/400x300?text=Doodle+1',
    'https://via.placeholder.com/400x300?text=Doodle+2',
    'https://via.placeholder.com/400x300?text=Doodle+3',
    'https://via.placeholder.com/400x300?text=Doodle+4',
    'https://via.placeholder.com/400x300?text=Doodle+5',
  ];

  final Random _random = Random();

  // Generate a drawing based on a word prompt
  Future<AIDrawingResult> generateDrawing({required String prompt}) async {
    // Simulate API call delay
    await Future.delayed(const Duration(seconds: 2));

    // In a real app, this would make an API call to the Hugging Face model
    // artificialguybr/doodle-redmond-doodle-hand-drawing-style-lora-for-sd-xl
    // Example API request (not implemented here):
    /*
    final response = await http.post(
      Uri.parse('https://api.huggingface.co/models/artificialguybr/doodle-redmond-doodle-hand-drawing-style-lora-for-sd-xl'),
      headers: {
        'Authorization': 'Bearer YOUR_API_KEY',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'inputs': prompt,
      }),
    );

    if (response.statusCode == 200) {
      // Process and return the image
      return AIDrawingResult(
        imageUrl: 'data:image/png;base64,${base64Encode(response.bodyBytes)}',
        prompt: prompt,
      );
    } else {
      throw Exception('Failed to generate AI drawing: ${response.body}');
    }
    */

    // For the mockup, return a random placeholder image
    final imageUrl =
        _placeholderImages[_random.nextInt(_placeholderImages.length)];

    return AIDrawingResult(imageUrl: imageUrl, prompt: prompt);
  }
}
