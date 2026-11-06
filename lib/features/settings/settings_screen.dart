import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/color_constants.dart';
import '../../core/widgets/sketch_widgets.dart';
import '../progression/progress_repository.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      body: SketchBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              Row(
                children: [
                  SketchIconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    semanticLabel: 'Back',
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text('Settings', style: SketchText.title, textAlign: TextAlign.center),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
              const SizedBox(height: 20),
              SketchPanel(
                seed: 71,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    _ToggleRow(
                      icon: Icons.volume_up_rounded,
                      label: 'Sound',
                      value: settings.sound,
                      onChanged: notifier.setSound,
                    ),
                    const _Divider(),
                    _ToggleRow(
                      icon: Icons.music_note_rounded,
                      label: 'Music',
                      value: settings.music,
                      onChanged: notifier.setMusic,
                    ),
                    const _Divider(),
                    _ToggleRow(
                      icon: Icons.vibration_rounded,
                      label: 'Haptics',
                      value: settings.haptics,
                      onChanged: notifier.setHaptics,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              SketchButton(
                color: SketchColors.coral,
                onPressed: () => _confirmReset(context, ref),
                child: const Text('Reset progress'),
              ),
              const SizedBox(height: 28),
              Text(
                'How to play\n'
                '• Tap an arrow to slide it off the board along its path.\n'
                '• It only escapes if nothing is in the way in front of its head.\n'
                '• A blocked arrow costs one heart — you have three per level.\n'
                '• Hints glow an arrow that can move right now.',
                style: SketchText.body.copyWith(color: SketchColors.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      barrierColor: SketchColors.outline.withValues(alpha: 0.4),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: SketchPanel(
          seed: 81,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Reset progress?', style: SketchText.heading),
              const SizedBox(height: 8),
              const Text(
                'All completed levels, stars and scores will be erased.',
                style: SketchText.body,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: SketchButton(
                      color: SketchColors.cream,
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SketchButton(
                      color: SketchColors.coral,
                      seed: 4,
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Reset'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (ok == true) {
      await ref.read(progressProvider.notifier).reset();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Progress reset')));
      }
    }
  }
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) => Container(height: 1.5, color: SketchColors.notebookLine);
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({required this.icon, required this.label, required this.value, required this.onChanged});
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: SketchColors.outline),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: SketchText.heading.copyWith(fontSize: 22))),
          Semantics(
            toggled: value,
            label: label,
            child: GestureDetector(
              onTap: () => onChanged(!value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 58,
                height: 32,
                padding: const EdgeInsets.all(3),
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                decoration: BoxDecoration(
                  color: value ? SketchColors.mint : SketchColors.lockedGrey,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: SketchColors.outline, width: 2.5),
                ),
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: SketchColors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: SketchColors.outline, width: 2),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
