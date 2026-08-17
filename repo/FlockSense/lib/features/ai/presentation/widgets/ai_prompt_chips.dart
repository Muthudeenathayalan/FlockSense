import 'package:flutter/material.dart';

class AiPromptChips extends StatelessWidget {
  final ValueChanged<String> onSelectPrompt;

  const AiPromptChips({super.key, required this.onSelectPrompt});

  static const _prompts = [
    '📊 Analyze my farm',
    '📈 Predict harvest weight',
    '⚠️ Why is mortality increasing?',
    '🌾 Feed recommendation',
    '💉 Vaccination schedule',
    '💰 Profit analysis',
    '📦 Inventory status',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        scrollDirection: Axis.horizontal,
        itemCount: _prompts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final prompt = _prompts[index];
          return ActionChip(
            backgroundColor: Colors.white,
            side: const BorderSide(color: Color(0xFFCBD5E1)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            label: Text(
              prompt,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF1B5E20)),
            ),
            onPressed: () => onSelectPrompt(prompt.replaceAll(RegExp(r'^[^\w]+'), '').trim()),
          );
        },
      ),
    );
  }
}
