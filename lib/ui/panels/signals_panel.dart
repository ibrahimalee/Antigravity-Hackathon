import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    final appState = ref.watch(crisisProvider);
    
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
        if (appState.currentState != null) const ConfidenceGaugCard(),
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
                  if (isUrdu) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _ParsedChip(icon: '📍', label: text.toLowerCase().contains('g-10') ? 'G-10' : 'Srinagar Hwy', delay: 0),
                        _ParsedChip(icon: '🌊', label: 'FLOOD', delay: 100),
                        _ParsedChip(icon: '🚗', label: 'Vehicles trapped', delay: 200),
                        _ParsedChip(icon: '🔴', label: 'HIGH', delay: 300),
                      ],
                    ),
                  ],
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

class ConfidenceGaugCard extends ConsumerStatefulWidget {
  const ConfidenceGaugCard({super.key});

  @override
  ConsumerState<ConfidenceGaugCard> createState() => _ConfidenceGaugCardState();
}

class _ConfidenceGaugCardState extends ConsumerState<ConfidenceGaugCard> {
  final Map<String, bool> _hasCrossedThreshold = {};

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(crisisProvider);
    final state = appState.currentState;
    if (state == null) return const SizedBox.shrink();

    final fusedSignals = state.agentTraces.agent1.fusedSignals.toList();
    if (fusedSignals.isEmpty) return const SizedBox.shrink();

    final countdownAsync = ref.watch(countdownProvider);
    final countdown = countdownAsync.value ?? 0;

    // We build gauges for all actual fused signals
    final List<Map<String, dynamic>> gaugesToBuild = fusedSignals.map((fs) => {
      'location': fs.location,
      'score': fs.credibilityScore,
    }).toList();

    // If Phase 1 countdown is active, inject a mock Murree Road gauge
    if (appState.currentPhaseNumber == 1 && countdown > 0 && countdown <= 12) {
      final murreeScore = 0.575 * ((12 - countdown) / 12.0);
      if (!gaugesToBuild.any((g) => g['location'].toString().toLowerCase().contains('murree'))) {
        gaugesToBuild.add({
          'location': 'Murree Road',
          'score': murreeScore,
        });
      }
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        children: gaugesToBuild.map((g) => _buildGauge(context, g['location'], g['score'])).toList(),
      ),
    );
  }

  Widget _buildGauge(BuildContext context, String location, double score) {
    final isCrisis = score >= 0.60;
    
    if (isCrisis && !(_hasCrossedThreshold[location] ?? false)) {
      _hasCrossedThreshold[location] = true;
      HapticFeedback.heavyImpact();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: surfaceLight.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isCrisis ? accentCritical.withOpacity(0.8) : surfaceLight),
        boxShadow: isCrisis ? [BoxShadow(color: accentCritical.withOpacity(0.2), blurRadius: 12, spreadRadius: 2)] : [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('SIGNAL FUSION CONFIDENCE: ${location.toUpperCase()}', style: inter(10, weight: FontWeight.w700, color: textSecondary, letterSpacing: 1)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isCrisis ? accentCritical.withOpacity(0.2) : accentWarning.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(isCrisis ? 'ACTIVE' : 'MONITORING', style: inter(9, color: isCrisis ? accentCritical : accentWarning, weight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    height: 12,
                    width: width,
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: score),
                    duration: 1500.ms,
                    curve: Curves.easeOutCubic,
                    builder: (context, val, child) {
                      return Container(
                        height: 12,
                        width: width * val,
                        decoration: BoxDecoration(
                          color: val >= 0.60 ? accentCritical : accentInfo,
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: val >= 0.60 ? [BoxShadow(color: accentCritical.withOpacity(0.8), blurRadius: 12, spreadRadius: 2)] : [],
                        ),
                      );
                    },
                  ),
                  Positioned(
                    left: width * 0.60,
                    top: -4,
                    bottom: -4,
                    child: Container(
                      width: 2,
                      decoration: BoxDecoration(
                        color: score >= 0.60 ? accentCritical : Colors.red.withOpacity(0.5),
                        boxShadow: score >= 0.60 ? [BoxShadow(color: accentCritical, blurRadius: 8, spreadRadius: 2)] : [],
                      ),
                    ),
                  ),
                  Positioned(
                    left: width * 0.60 - 45,
                    top: -16,
                    child: Text('CRISIS THRESHOLD', style: inter(8, color: textSecondary, weight: FontWeight.w600)),
                  ),
                  if (score > 0 && score < 0.60)
                    Positioned(
                      right: 0,
                      top: 18,
                      child: Text('Needs 1 more corroborating source', style: inter(9, color: accentWarning)),
                    )
                ],
              );
            }
          ),
          SizedBox(height: score > 0 && score < 0.60 ? 20 : 4),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.1);
  }
}

class _ParsedChip extends StatelessWidget {
  final String icon;
  final String label;
  final int delay;
  
  const _ParsedChip({required this.icon, required this.label, required this.delay});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 10)),
          const SizedBox(width: 4),
          Text(label, style: inter(9, color: textSecondary, weight: FontWeight.w600)),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms, delay: delay.ms).scale(begin: const Offset(0.8, 0.8));
  }
}
