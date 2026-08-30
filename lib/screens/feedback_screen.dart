import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_config.dart';
import '../services/offline_service.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  int _rating = 5;
  String _category = 'Curriculum/Content';
  final _messageController = TextEditingController();
  bool _isSubmitting = false;

  final List<String> _categories = [
    'Curriculum/Content',
    'App Feature',
    'Bug Report',
    'Worksheet Request',
    'General',
  ];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    if (_messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('እባክዎ አስተያየትዎን ይፃፉ / Please enter your feedback message'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final offline = context.read<OfflineService>();
    final isAm = offline.language == LanguageCode.am;

    await offline.submitFeedback(
      rating: _rating,
      category: _category,
      message: _messageController.text.trim(),
    );

    setState(() => _isSubmitting = false);

    if (mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppConfig.darkCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.check_circle, color: AppConfig.primaryGreen, size: 24),
              const SizedBox(width: 8),
              Text(
                isAm ? 'አስተያየትዎ ደርሶናል!' : 'Thank You!',
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
          content: Text(
            isAm
                ? 'አስተያየትዎን ስለላኩልን እናመሰግናለን። መተግበሪያውን ለማሻሻል እንጠቀምበታለን።'
                : 'Your feedback has been successfully received and will help us improve Smart X Academy.',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConfig.primaryGreen,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: Text(isAm ? 'እሺ' : 'OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final offline = context.watch<OfflineService>();
    final isAm = offline.language == LanguageCode.am;

    return Scaffold(
      backgroundColor: AppConfig.darkBackground,
      appBar: AppBar(
        backgroundColor: AppConfig.darkCard,
        elevation: 0,
        title: Text(
          isAm ? 'አስተያየት ይስጡ' : 'Send Feedback',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Intro Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppConfig.darkCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppConfig.primaryGreen.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppConfig.primaryGreen.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.rate_review_outlined, color: AppConfig.primaryGreen, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isAm ? 'የተጠቃሚዎች ድምፅ ለእኛ አስፈላጊ ነው' : 'We Value Your Feedback',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isAm
                              ? 'ጥያቄዎች ላይ ስህተት ካለ፣ አዳዲስ ኖቶች ወይም ዎርክሺቶች እንዲጨመሩ ከፈለጉ ይፃፉልን።'
                              : 'Let us know how we can make learning easier and more effective for you.',
                          style: const TextStyle(color: Colors.white60, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Rating Stars
            Text(
              isAm ? 'የመተግበሪያው ደረጃ (Rating)' : 'Rate Your Experience',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppConfig.darkCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final starNum = index + 1;
                  final isSelected = starNum <= _rating;
                  return IconButton(
                    icon: Icon(
                      isSelected ? Icons.star_rounded : Icons.star_border_rounded,
                      color: isSelected ? AppConfig.accentAmber : Colors.white30,
                      size: 32,
                    ),
                    onPressed: () => setState(() => _rating = starNum),
                  );
                }),
              ),
            ),
            const SizedBox(height: 20),

            // Category selector
            Text(
              isAm ? 'የአስተያየቱ ዘርፍ' : 'Feedback Category',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((cat) {
                final isSelected = _category == cat;
                return ChoiceChip(
                  label: Text(cat),
                  selected: isSelected,
                  selectedColor: AppConfig.primaryGreen,
                  backgroundColor: AppConfig.darkCard,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: isSelected ? AppConfig.primaryGreen : Colors.white12),
                  ),
                  onSelected: (val) {
                    if (val) setState(() => _category = cat);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Message text area
            Text(
              isAm ? 'አስተያየትዎ / መልእክትዎ' : 'Your Message / Suggestions',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _messageController,
              maxLines: 5,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: isAm
                    ? 'አስተያየትዎን፣ ጥያቄዎን ወይም የተመለከቱትን ስህተት እዚህ ይፃፉ...'
                    : 'Write your suggestions, reported errors, or requested topics here...',
                hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                filled: true,
                fillColor: AppConfig.darkCard,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppConfig.primaryGreen),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConfig.primaryGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isSubmitting ? null : _submitFeedback,
                icon: _isSubmitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.send_rounded),
                label: Text(
                  _isSubmitting
                      ? (isAm ? 'በመላክ ላይ...' : 'Sending...')
                      : (isAm ? 'አስተያየት ላክ' : 'Submit Feedback'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
