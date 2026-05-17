import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/crisis_provider.dart';
import '../design_system.dart';

class SignalFeedPanel extends ConsumerStatefulWidget {
  const SignalFeedPanel({super.key});

  @override
  ConsumerState<SignalFeedPanel> createState() => _SignalFeedPanelState();
}

class _SignalFeedPanelState extends ConsumerState<SignalFeedPanel> {
  int _lastCount = 0;
  bool _isUpdating = false;

  @override
  Widget build(BuildContext context) {
    final signals = ref.watch(activeSignalsProvider);
    
    if (signals.length > _lastCount) {
      _lastCount = signals.length;
      _isUpdating = true;
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) setState(() => _isUpdating = false);
      });
    } else if (signals.length < _lastCount) {
      _lastCount = signals.length;
    }

    if (signals.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sensors_off_rounded, size: 64, color: textSecondary.withOpacity(0.4)),
            const SizedBox(height: 16),
            Text('Awaiting signals...', style: inter(14, color: textSecondary)),
            const SizedBox(height: 4),
            Text('Tap SIMULATE to begin', style: inter(12, color: textSecondary.withOpacity(0.6))),
          ],
        ),
      );
    }

    final reversed = signals.reversed.toList();

    return Column(
      children: [
        // Summary Header Row
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            children: [
              Row(
                children: [
                  Text('LIVE SIGNAL FEED', style: inter(11, weight: FontWeight.w500, color: accentInfo, letterSpacing: 2)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: surfaceLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('${signals.length}', style: inter(11, color: accentInfo, weight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 2,
                child: _isUpdating
                    ? const LinearProgressIndicator(
                        backgroundColor: Colors.transparent,
                        valueColor: AlwaysStoppedAnimation<Color>(accentInfo),
                      ).animate().fadeIn(duration: 200.ms)
                    : null,
              ),
            ],
          ),
        ),
        // Signal List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            itemCount: reversed.length,
            itemBuilder: (context, index) {
              final sig = reversed[index];
              return _SignalCard(
                key: ValueKey(sig['id']),
                signal: sig,
              ).animate().fadeIn(duration: 300.ms).slideX(begin: -0.05);
            },
          ),
        ),
      ],
    );
  }
}

class _SignalCard extends StatelessWidget {
  final Map<String, dynamic> signal;
  const _SignalCard({super.key, required this.signal});

  bool _isUrdu(String text) {
    final lower = text.toLowerCase();
    final words = ['mein', 'hai', 'pani', 'sarak', 'ki', 'ho', 'rahi', 'hua', 'gayi', 'pe', 'bhar', 'buri', 'tarah', 'hadsa'];
    for (final w in words) {
      if (lower.contains(w)) return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    String rawSource = signal['source'] ?? 'sensor';
    if (rawSource == 'anonymous_social') rawSource = 'social_post';
    
    Color sourceColor;
    IconData sourceIcon;
    switch (rawSource) {
      case 'social_post':
        sourceColor = accentCritical;
        sourceIcon = Icons.people_alt_rounded;
        break;
      case 'weather_api':
        sourceColor = accentInfo;
        sourceIcon = Icons.cloud_rounded;
        break;
      case 'traffic_api':
        sourceColor = accentWarning;
        sourceIcon = Icons.traffic_rounded;
        break;
      case 'field_report':
        sourceColor = accentSafe;
        sourceIcon = Icons.assignment_ind_rounded;
        break;
      default:
        sourceColor = accentPurple;
        sourceIcon = Icons.sensors_rounded;
    }

    final double cred = signal['base_credibility'] ?? 0.0;
    Color credColor;
    if (cred >= 0.7) {
      credColor = accentSafe;
    } else if (cred >= 0.4) {
      credColor = accentWarning;
    } else {
      credColor = accentCritical;
    }

    final text = signal['text'] ?? '';
    final isUrdu = _isUrdu(text);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        borderRadius: 8,
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Column
            SizedBox(
              width: 48,
              child: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: sourceColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: sourceColor.withOpacity(0.5), width: 1),
                ),
                alignment: Alignment.center,
                child: Icon(sourceIcon, color: Colors.white, size: 18),
              ),
            ),
            
            // Middle Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(rawSource.toUpperCase().replaceAll('_', ' '),
                          style: inter(10, weight: FontWeight.w500, color: textSecondary, letterSpacing: 1.5)),
                      const Spacer(),
                      Text(signal['timestamp'] ?? '', style: inter(10, color: textSecondary).copyWith(fontFeatures: [const FontFeature.tabularFigures()])),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: inter(13, color: textPrimary).copyWith(height: isUrdu ? 1.5 : 1.2),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            
            // Right Column
            SizedBox(
              width: 72,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: credColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(cred.toStringAsFixed(2), style: inter(13, weight: FontWeight.w600, color: credColor)),
                  ),
                  const SizedBox(height: 4),
                  Text('CRED', style: inter(9, color: textSecondary, letterSpacing: 1)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
