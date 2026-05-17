import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/crisis_state.dart';
import '../../providers/crisis_provider.dart';
import '../design_system.dart';

class TracesPanel extends ConsumerWidget {
  const TracesPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stateAsync = ref.watch(currentCrisisStateProvider);

    return stateAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: accentInfo, strokeWidth: 2)),
      error: (e, _) => Center(child: Text('Error: $e', style: inter(12, color: accentCritical))),
      data: (state) {
        if (state == null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.psychology_rounded, size: 64, color: textSecondary.withOpacity(0.4)),
                const SizedBox(height: 16),
                Text('Agent traces will appear here', style: inter(14, color: textSecondary)),
                const SizedBox(height: 4),
                Text('Tap SIMULATE to begin', style: inter(12, color: textSecondary.withOpacity(0.6))),
              ],
            ),
          );
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('SYSTEM TRACES', style: syne(14, color: textSecondary, weight: FontWeight.w700, letterSpacing: 1.5)),
                ElevatedButton.icon(
                  onPressed: () {
                    final traceData = '''
=== ANTIGRAVITY CIRO AGENT TRACE EXPORT ===
Timestamp: ${DateTime.now().toIso8601String()}

--- AGENT 1: SIGNAL FUSION ---
${state.agentTraces.agent1.steps.join('\n')}

--- AGENT 2: CRISIS DETECTION ---
${state.agentTraces.agent2.steps.join('\n')}

--- AGENT 3: RESOURCE ALLOCATION ---
${state.agentTraces.agent3.steps.join('\n')}
''';
                    Share.share(traceData, subject: 'CIRO Agent Traces');
                  },
                  icon: const Icon(Icons.download_rounded, size: 14),
                  label: Text('EXPORT TRACE', style: inter(10, weight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: surfaceLight,
                    foregroundColor: accentInfo,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _TraceCard('AGENT 1: SIGNAL FUSION', accentInfo, state.agentTraces.agent1.steps.join('\n')),
            const SizedBox(height: 12),
            _TraceCard('AGENT 2: CRISIS DETECTION', accentWarning, state.agentTraces.agent2.steps.join('\n')),
            const SizedBox(height: 12),
            _TraceCard('AGENT 3: RESOURCE ALLOCATION', accentPurple, state.agentTraces.agent3.steps.join('\n')),
          ],
        );
      },
    );
  }
}

class _TraceCard extends StatelessWidget {
  final String title;
  final Color color;
  final String rawOutput;
  
  const _TraceCard(this.title, this.color, this.rawOutput);

  @override
  Widget build(BuildContext context) {
    final lines = rawOutput.isEmpty ? ['[system] Waiting for agent activation...'] : rawOutput.split('\n');

    return GlassCard(
      accentColor: color,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.memory_rounded, size: 16, color: color),
              const SizedBox(width: 8),
              Text(title, style: inter(12, color: color, weight: FontWeight.w600, letterSpacing: 1.5)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bgPrimary.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: surfaceLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: lines.map((l) => _buildLine(l)).toList(),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.05);
  }

  Widget _buildLine(String line) {
    String prefix = '';
    String content = line;
    if (!line.trim().startsWith('[')) {
      final now = DateTime.now();
      prefix = '[${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}] ';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontFamily: 'RobotoMono', fontSize: 11, color: Color(0xFFD4D4D8), height: 1.4),
          children: _parseLine(prefix + content),
        ),
      ),
    );
  }

  List<TextSpan> _parseLine(String line) {
    if (line.contains('CONFIDENCE:')) return _splitByWord(line, 'CONFIDENCE:', accentInfo);
    if (line.contains('SEVERITY:')) return _splitByWord(line, 'SEVERITY:', accentCritical);
    if (line.contains('ALLOCATED:')) return _splitByWord(line, 'ALLOCATED:', accentSafe);
    if (line.contains('WARNING:')) return _splitByWord(line, 'WARNING:', accentWarning);
    if (line.contains('ERROR:')) return _splitByWord(line, 'ERROR:', accentCritical, isBold: true);
    return [TextSpan(text: line)];
  }

  List<TextSpan> _splitByWord(String text, String keyword, Color color, {bool isBold = false}) {
    final idx = text.indexOf(keyword);
    if (idx == -1) return [TextSpan(text: text)];
    return [
      TextSpan(text: text.substring(0, idx)),
      TextSpan(text: keyword, style: TextStyle(color: color, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
      TextSpan(text: text.substring(idx + keyword.length)),
    ];
  }
}
