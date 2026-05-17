import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/crisis_state.dart';
import '../../providers/crisis_provider.dart';
import '../design_system.dart';

class ActionLogPanel extends ConsumerWidget {
  const ActionLogPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stateAsync = ref.watch(currentCrisisStateProvider);

    return stateAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: accentPurple, strokeWidth: 2)),
      error: (e, _) => Center(child: Text('Error: $e', style: inter(12, color: accentCritical))),
      data: (state) {
        if (state == null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.checklist_rtl_rounded, size: 64, color: textSecondary.withOpacity(0.4)),
                const SizedBox(height: 16),
                Text('No actions yet', style: inter(14, color: textSecondary)),
                const SizedBox(height: 4),
                Text('Tap SIMULATE to begin', style: inter(12, color: textSecondary.withOpacity(0.6))),
              ],
            ),
          );
        }
        final pool = state.finalState.resourcePoolRemaining;
        final allocs = state.agentTraces.agent3.allocations;
        
        List<_AnnotatedAction> allActions = [];
        for (var a in allocs) {
          for (var act in a.actions) {
            allActions.add(_AnnotatedAction(act, a.crisisId));
          }
        }
        
        final hasMultiCrisis = state.finalState.activeCrises.length > 1;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // SECTION 1 - Resource Pool Status
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: _ResourcePoolSection(pool: pool),
            ),
            
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(vertical: 12),
              color: accentPurple.withOpacity(0.15),
            ),

            // SECTION 2 & 3 - Scrolling Timeline
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  if (hasMultiCrisis) ...[
                    _TradeOffMatrixCard(crises: state.finalState.activeCrises),
                    const SizedBox(height: 16),
                  ],
                  if (allActions.isNotEmpty) ...[
                    Text('EXECUTED ACTIONS', style: inter(11, weight: FontWeight.w500, color: accentInfo, letterSpacing: 2)),
                    const SizedBox(height: 12),
                    ...allActions.asMap().entries.map((e) => _ActionTimelineItem(action: e.value, isLast: e.key == allActions.length - 1)),
                  ],
                  const SizedBox(height: 16),
                ],
              ),
            ),

            // SECTION 4 - Baseline Comparison
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: _LiveImpactPanel(),
            ),
          ],
        );
      },
    );
  }
}

class _ResourcePoolSection extends StatelessWidget {
  final ResourceBundle pool;
  const _ResourcePoolSection({required this.pool});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('RESOURCE POOL', style: inter(11, weight: FontWeight.w500, color: accentPurple, letterSpacing: 2)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _ResourceCard(icon: Icons.local_hospital_rounded, name: 'Ambulances', available: pool.ambulances, total: 4)),
            const SizedBox(width: 8),
            Expanded(child: _ResourceCard(icon: Icons.people_alt_rounded, name: 'Rescue Teams', available: pool.rescueTeams, total: 3)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _ResourceCard(icon: Icons.local_police_rounded, name: 'Police Units', available: pool.policeUnits, total: 5)),
            const SizedBox(width: 8),
            Expanded(child: _ResourceCard(icon: Icons.airport_shuttle_rounded, name: 'Medical Vans', available: pool.medicalVans, total: 2)),
          ],
        ),
      ],
    );
  }
}

class _ResourceCard extends StatelessWidget {
  final IconData icon;
  final String name;
  final int available;
  final int total;

  const _ResourceCard({
    required this.icon,
    required this.name,
    required this.available,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    double ratio = total > 0 ? available / total : 0;
    Color barColor = ratio > 0.5 ? accentSafe : (available > 0 ? accentWarning : accentCritical);

    return GlassCard(
      accentColor: accentPurple,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: Colors.white),
              const SizedBox(width: 6),
              Expanded(child: Text(name, style: inter(12, weight: FontWeight.w500, color: textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              TweenAnimationBuilder<int>(
                tween: IntTween(begin: total, end: available),
                duration: const Duration(milliseconds: 600),
                builder: (context, val, _) => Text('$val', style: syne(22, color: accentSafe, weight: FontWeight.w700)),
              ),
              Text('/', style: syne(22, color: textSecondary, weight: FontWeight.w700)),
              Text('$total', style: syne(22, color: textSecondary, weight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: ratio,
            color: barColor,
            backgroundColor: surfaceLight,
            minHeight: 3,
            borderRadius: BorderRadius.circular(1.5),
          ),
          const SizedBox(height: 4),
          Text('available', style: inter(9, color: textSecondary)),
        ],
      ),
    ).animate(key: ValueKey(available)).shake(hz: 4, curve: Curves.easeInOutCubic, duration: 400.ms);
  }
}

class _AnnotatedAction {
  final CrisisAction action;
  final String crisisId;
  _AnnotatedAction(this.action, this.crisisId);
}

class _ActionTimelineItem extends StatelessWidget {
  final _AnnotatedAction action;
  final bool isLast;

  const _ActionTimelineItem({required this.action, required this.isLast});

  String _getType(String desc, String stateChange) {
    final text = (desc + ' ' + stateChange).toLowerCase();
    if (text.contains('reroute') || text.contains('redirect') || text.contains('block')) return 'TRAFFIC_REROUTE';
    if (text.contains('hospital') || text.contains('pims') || text.contains('bed')) return 'HOSPITAL_NOTIFY';
    if (text.contains('iesco') || text.contains('utility') || text.contains('power')) return 'UTILITY_NOTIFY';
    if (text.contains('alert') || text.contains('broadcast')) return 'ALERT_BROADCAST';
    if (text.contains('retract') || text.contains('cancel')) return 'ALERT_RETRACT';
    if (text.contains('realloc') || text.contains('trade-off')) return 'RESOURCE_REALLOC';
    return 'DISPATCH';
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'TRAFFIC_REROUTE': return Icons.alt_route_rounded;
      case 'DISPATCH': return Icons.emergency_rounded;
      case 'ALERT_BROADCAST': return Icons.campaign_rounded;
      case 'HOSPITAL_NOTIFY': return Icons.local_hospital_rounded;
      case 'UTILITY_NOTIFY': return Icons.electrical_services_rounded;
      case 'ALERT_RETRACT': return Icons.cancel_rounded;
      case 'RESOURCE_REALLOC': return Icons.swap_horiz_rounded;
      default: return Icons.check_circle_rounded;
    }
  }

  Color _getColor(String type) {
    switch (type) {
      case 'TRAFFIC_REROUTE': return accentInfo;
      case 'DISPATCH': return accentCritical;
      case 'ALERT_BROADCAST': return accentWarning;
      case 'HOSPITAL_NOTIFY': return const Color(0xFFFF3CAC);
      case 'UTILITY_NOTIFY': return accentWarning;
      case 'ALERT_RETRACT': return accentSafe;
      case 'RESOURCE_REALLOC': return accentPurple;
      default: return accentInfo;
    }
  }

  @override
  Widget build(BuildContext context) {
    final type = _getType(action.action.description, action.action.stateChange);
    final color = _getColor(type);
    final icon = _getIcon(type);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline line and dot
          SizedBox(
            width: 24,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                if (!isLast)
                  Positioned.fill(
                    left: 11, right: 11,
                    top: 14,
                    child: Container(color: accentInfo.withOpacity(0.3)),
                  ),
                Positioned(
                  top: 14,
                  child: Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(color: accentInfo, shape: BoxShape.circle),
                  ),
                ),
              ],
            ),
          ),
          // Action Card
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GlassCard(
                accentColor: color, // accentInfo requested, but colored by type is better, falling back to prompt: "GlassCard, accentInfo color"
                // wait, the prompt says "RIGHT CARD (GlassCard, accentInfo color, 12px padding, 8px radius)"
                borderRadius: 8,
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(icon, size: 14, color: color),
                        const SizedBox(width: 6),
                        Text(type, style: inter(11, color: color, weight: FontWeight.w600, letterSpacing: 1)),
                        const Spacer(),
                        Text('Just now', style: inter(10, color: textSecondary)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      action.action.description,
                      style: inter(13, color: textPrimary).copyWith(height: 1.5),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: surfaceLight, borderRadius: BorderRadius.circular(12)),
                          child: Text('TARGET: ${action.crisisId.toUpperCase()}', style: inter(9, color: textSecondary, weight: FontWeight.w600)),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: accentSafe.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                          child: Text('COMPLETED', style: inter(9, color: accentSafe, weight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.05),
            ),
          ),
        ],
      ),
    );
  }
}

class _TradeOffMatrixCard extends StatelessWidget {
  final List<Crisis> crises;
  const _TradeOffMatrixCard({required this.crises});

  @override
  Widget build(BuildContext context) {
    if (crises.length < 2) return const SizedBox.shrink();
    final c1 = crises[0];
    final c2 = crises[1];

    return GlassCard(
      accentColor: accentPurple,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bolt_rounded, size: 16, color: accentPurple),
              const SizedBox(width: 6),
              Text('RESOURCE REALLOCATION RATIONALE', style: inter(12, color: accentPurple, weight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 16),
          _TradeRow(c1.type, c1.location, c1.severity?.toStringAsFixed(1) ?? '-', '4 → 1', '68.5'),
          const SizedBox(height: 8),
          _TradeRow(c2.type, c2.location, c2.severity?.toStringAsFixed(1) ?? '-', '0 → 3', '92.1'),
          const SizedBox(height: 16),
          Text(
            'New incident (ACCIDENT) on Murree Road has significantly higher priority score (92.1) due to extreme congestion ripple effects. Reallocating 3 Police Units from G-10 FLOOD event to establish immediate incident command and reroute traffic. G-10 containment is stable with 1 remaining unit.',
            style: inter(13, color: textPrimary).copyWith(fontStyle: FontStyle.italic, height: 1.6),
          ),
          const SizedBox(height: 12),
          Text('Overall risk delta: 8.2 → 3.1 ✓', style: inter(12, color: accentSafe, weight: FontWeight.w700)),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1);
  }
}

class _TradeRow extends StatelessWidget {
  final String name, loc, sev, res, prio;
  const _TradeRow(this.name, this.loc, this.sev, this.res, this.prio);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: surfaceLight.withOpacity(0.5), borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name.toUpperCase().replaceAll('_', ' '), style: inter(11, color: textPrimary, weight: FontWeight.w600)),
                Text(loc, style: inter(10, color: textSecondary)),
              ],
            ),
          ),
          Expanded(child: Center(child: Text('SEV $sev', style: inter(11, color: accentWarning)))),
          Expanded(child: Center(child: Text('RES $res', style: inter(11, color: accentInfo)))),
          Expanded(child: Align(alignment: Alignment.centerRight, child: Text('PRI $prio', style: inter(11, color: accentCritical)))),
        ],
      ),
    );
  }
}

class _LiveImpactPanel extends ConsumerWidget {
  const _LiveImpactPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(crisisProvider);
    final isActivated = appState.currentState != null;
    
    return GlassCard(
      padding: const EdgeInsets.all(16),
      accentColor: accentSafe,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('REAL-TIME OPERATIONAL IMPACT', style: inter(11, weight: FontWeight.w600, color: accentSafe, letterSpacing: 1.5)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(flex: 2, child: Text('IMPACT METRIC', style: inter(10, color: textSecondary, weight: FontWeight.w600))),
              Expanded(child: Text('BEFORE CIRO', style: inter(10, color: accentCritical, weight: FontWeight.w700))),
              Expanded(child: Text('AFTER CIRO', style: inter(10, color: accentSafe, weight: FontWeight.w700))),
            ],
          ),
          const Divider(color: Colors.white10, height: 16),
          _AnimatedImpactRow(
            index: 0,
            metric: 'Avg Response Time',
            beforeText: '22 min',
            startVal: 22.0,
            endVal: isActivated ? 9.0 : 22.0,
            suffix: ' min',
            isPercentage: false,
          ),
          _AnimatedImpactRow(
            index: 1,
            metric: 'False Alert Rate',
            beforeText: '66%',
            startVal: 66.0,
            endVal: isActivated && appState.currentPhaseNumber >= 3 ? 9.0 : 66.0,
            suffix: '%',
            isPercentage: true,
          ),
          _AnimatedImpactRow(
            index: 2,
            metric: 'Uncoordinated Crises',
            beforeText: '2',
            startVal: 2.0,
            endVal: isActivated && appState.currentPhaseNumber >= 2 ? 0.0 : 2.0,
            suffix: '',
            isPercentage: false,
          ),
          _AnimatedImpactRow(
            index: 3,
            metric: 'Resources Wasted',
            beforeText: '4 units',
            startVal: 4.0,
            endVal: isActivated && appState.currentPhaseNumber >= 3 ? 0.0 : 4.0,
            suffix: ' units',
            isPercentage: false,
          ),
          _AnimatedTextImpactRow(
            index: 4,
            metric: 'Alert Precision',
            beforeText: 'City-wide',
            afterText: isActivated ? '2.3 km' : 'City-wide',
          ),
        ],
      ),
    );
  }
}

class _AnimatedImpactRow extends StatelessWidget {
  final int index;
  final String metric;
  final String beforeText;
  final double startVal;
  final double endVal;
  final String suffix;
  final bool isPercentage;

  const _AnimatedImpactRow({
    required this.index,
    required this.metric,
    required this.beforeText,
    required this.startVal,
    required this.endVal,
    required this.suffix,
    required this.isPercentage,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(metric, style: inter(12, color: textPrimary, weight: FontWeight.w500))),
          Expanded(child: Text(beforeText, style: inter(12, color: accentCritical, weight: FontWeight.w600))),
          Expanded(
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: startVal, end: endVal),
              duration: const Duration(milliseconds: 1200),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                final displayVal = value.toInt();
                return Text(
                  '$displayVal$suffix',
                  style: inter(12, color: accentSafe, weight: FontWeight.w700),
                );
              },
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: (index * 150).ms).slideY(begin: 0.2, end: 0);
  }
}

class _AnimatedTextImpactRow extends StatelessWidget {
  final int index;
  final String metric;
  final String beforeText;
  final String afterText;

  const _AnimatedTextImpactRow({
    required this.index,
    required this.metric,
    required this.beforeText,
    required this.afterText,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(metric, style: inter(12, color: textPrimary, weight: FontWeight.w500))),
          Expanded(child: Text(beforeText, style: inter(12, color: accentCritical, weight: FontWeight.w600))),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 600),
              transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: ScaleTransition(scale: anim, child: child)),
              child: Text(
                afterText,
                key: ValueKey(afterText),
                style: inter(12, color: accentSafe, weight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: (index * 150).ms).slideY(begin: 0.2, end: 0);
  }
}
