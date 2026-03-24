import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/translation_mode.dart';
import '../providers/mode_provider.dart';

class ModeToggle extends ConsumerWidget {
  const ModeToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(translationModeProvider);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Chip(
          label: 'EN→JP',
          active: mode == TranslationMode.enToJp,
          onTap: () => ref.read(translationModeProvider.notifier).state =
              TranslationMode.enToJp,
        ),
        const SizedBox(width: 6),
        _Chip(
          label: 'JP→EN',
          active: mode == TranslationMode.jpToEn,
          onTap: () => ref.read(translationModeProvider.notifier).state =
              TranslationMode.jpToEn,
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: active ? Colors.blueAccent : Colors.grey.shade900,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active ? Colors.blueAccent : Colors.grey.shade700,
            width: 0.8,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
            color: active ? Colors.white : Colors.white54,
          ),
        ),
      ),
    );
  }
}
