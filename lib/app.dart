import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/pipeline_provider.dart';
import 'screens/idle_screen.dart';
import 'screens/recording_screen.dart';
import 'screens/processing_screen.dart';
import 'screens/result_screen.dart';
import 'screens/error_screen.dart';

class SpeakEasyApp extends ConsumerWidget {
  const SpeakEasyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pipeline = ref.watch(pipelineProvider);

    Widget screen = switch (pipeline) {
      PipelineState.idle       => const IdleScreen(),
      PipelineState.recording  => const RecordingScreen(),
      PipelineState.processing => const ProcessingScreen(),
      PipelineState.result     => const ResultScreen(),
      PipelineState.error      => const ErrorScreen(),
    };

    return MaterialApp(
      title: 'SpeakEasy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        colorScheme: const ColorScheme.dark(primary: Colors.blueAccent),
      ),
      home: screen,
    );
  }
}
