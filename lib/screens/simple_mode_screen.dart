import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/metronome_provider.dart';
import '../widgets/tempo_input.dart';
import '../widgets/time_signature_picker.dart';

/// Simple mode screen with tempo and time signature controls
class SimpleModeScreen extends StatelessWidget {
  const SimpleModeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MetronomeProvider>(
      builder: (context, provider, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              
              // Tempo input
              TempoInput(
                bpm: provider.state.bpm,
                onChanged: provider.setTempo,
              ),
              
              const SizedBox(height: 48),
              
              // Time signature picker
              TimeSignaturePicker(
                selected: provider.state.timeSignature,
                onChanged: provider.setTimeSignature,
              ),
            ],
          ),
        );
      },
    );
  }
}
