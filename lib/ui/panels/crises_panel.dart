import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/crisis_state.dart';
import '../../providers/crisis_provider.dart';
import '../design_system.dart';

class CrisisListPanel extends ConsumerWidget {
  const CrisisListPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stateAsync = ref.watch(currentCrisisStateProvider);

    return stateAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: accentWarning, strokeWidth: 2)),
      error: (e, _) => Center(child: Text('Error: $e', style: inter(12, color: accentCritical))),
      data: (state) {
        if (state == null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.crisis_alert_rounded, size: 64, color: textSecondary.withOpacity(0.4)),
                const SizedBox(height: 16),
                Text('No crisis data yet', style: inter(14, color: textSecondary)),
                const SizedBox(height: 4),
                Text('Tap SIMULATE to begin', style: inter(12, color: textSecondary.withOpacity(0.6))),
              ],
            ),
          );
        }
        final active = state.finalState.activeCrises;
        final monitoring = state.finalState.monitoringEvents;
        final allocations = state.agentTraces.agent3.allocations;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          children: [
            Row(
              children: [
                Expanded(
                  child: GlassCard(
                    accentColor: accentCritical,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text('${active.length}', style: syne(28, color: accentCritical, weight: FontWeight.w700)),
                        Text('ACTIVE CRISES', style: inter(10, color: textSecondary, letterSpacing: 1)),
                      ],
                    ),
                  ).animate().fadeIn().slideY(begin: 0.1),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GlassCard(
                    accentColor: accentWarning,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text('${monitoring.length}', style: syne(28, color: accentWarning, weight: FontWeight.w700)),
                        Text('MONITORING', style: inter(10, color: textSecondary, letterSpacing: 1)),
                      ],
                    ),
                  ).animate().fadeIn().slideY(begin: 0.1, delay: 100.ms),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...active.asMap().entries.map((e) => _buildCard(context, e.value, allocations, e.key)),
            ...monitoring.asMap().entries.map((e) => _buildCard(context, e.value, allocations, active.length + e.key)),
          ],
        );
      },
    );
  }

  Widget _buildCard(BuildContext context, Crisis crisis, List<ResourceAllocation> allocations, int index) {
    return _CrisisCard(
      crisis: crisis,
      allocation: allocations.where((a) => a.crisisId == crisis.id).firstOrNull,
    ).animate(delay: (index * 80 + 200).ms).fadeIn(duration: 400.ms).slideX(begin: -0.05);
  }
}

class _CrisisCard extends StatelessWidget {
  final Crisis crisis;
  final ResourceAllocation? allocation;

  const _CrisisCard({required this.crisis, this.allocation});

  void _showModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CrisisDetailModal(crisis: crisis, allocation: allocation),
    );
  }

  @override
  Widget build(BuildContext context) {
    final severity = crisis.severity ?? 0.0;
    Color accentColor;
    if (severity >= 7) {
      accentColor = accentCritical;
    } else if (severity >= 4) {
      accentColor = accentWarning;
    } else {
      accentColor = accentSafe;
    }

    if (crisis.status == CrisisStatus.monitoring && crisis.severity == null) {
      accentColor = accentWarning;
    }

    IconData typeIcon = Icons.warning_rounded;
    final tLower = crisis.type.toLowerCase();
    if (tLower.contains('flood')) typeIcon = Icons.water_damage_rounded;
    else if (tLower.contains('accident')) typeIcon = Icons.car_crash_rounded;
    else if (tLower.contains('heat')) typeIcon = Icons.thermostat_rounded;
    else if (tLower.contains('power')) typeIcon = Icons.electrical_services_rounded;
    else if (tLower.contains('infra')) typeIcon = Icons.construction_rounded;
    else if (tLower.contains('fire')) typeIcon = Icons.local_fire_department_rounded;

    return GestureDetector(
      onTap: () => _showModal(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: GlassCard(
          accentColor: accentColor,
          borderRadius: 16,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ROW 1 - Header
              Row(
                children: [
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(color: accentColor.withOpacity(0.2), shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: Icon(typeIcon, color: accentColor, size: 16),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(crisis.type.toUpperCase().replaceAll('_', ' '), style: inter(14, weight: FontWeight.w600, color: textPrimary)),
                        Row(
                          children: [
                            const Icon(Icons.location_on_rounded, size: 12, color: textSecondary),
                            const SizedBox(width: 4),
                            Text(crisis.location, style: inter(12, color: textSecondary)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  _StatusBadge(status: crisis.status, color: accentColor),
                ],
              ),
              const SizedBox(height: 8),

              // ROW 2 - Severity and Confidence
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('SEVERITY', style: inter(9, color: textSecondary, letterSpacing: 1.5)),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(crisis.severity?.toStringAsFixed(1) ?? '-', style: syne(32, weight: FontWeight.w700, color: accentColor)),
                            Text('/10', style: inter(16, color: textSecondary)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('CONFIDENCE', style: inter(9, color: textSecondary, letterSpacing: 1.5)),
                        const SizedBox(height: 8),
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: crisis.confidence),
                          duration: const Duration(milliseconds: 1200),
                          curve: Curves.easeOutCubic,
                          builder: (_, val, __) => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              LinearProgressIndicator(
                                value: val, color: accentColor,
                                backgroundColor: surfaceLight, minHeight: 6,
                                borderRadius: BorderRadius.circular(3),
                              ),
                              const SizedBox(height: 4),
                              Text('${(val * 100).toInt()}%', style: inter(12, color: accentColor)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // ROW 3 - Radius and Cascades
              Row(
                children: [
                  const Icon(Icons.radar_rounded, size: 14, color: textSecondary),
                  const SizedBox(width: 6),
                  Text('${crisis.affectedRadiusKm?.toStringAsFixed(1) ?? "-"} km radius', style: inter(12, color: textSecondary)),
                  const Spacer(),
                  const Icon(Icons.warning_amber_rounded, size: 14, color: accentWarning),
                  const SizedBox(width: 6),
                  Text('${crisis.cascadeEffects.length} cascades', style: inter(12, color: accentWarning)),
                ],
              ),
              
              if (crisis.cascadeEffects.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6, runSpacing: 6,
                  children: crisis.cascadeEffects.map((c) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: surfaceLight,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: accentWarning.withOpacity(0.3)),
                    ),
                    child: Text(c, style: inter(11, color: accentWarning)),
                  )).toList(),
                ),
              ],

              // ROW 4 - Stakeholders
              if (allocation != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    _StakeholderChip(icon: Icons.local_hospital_rounded, color: Colors.pinkAccent),
                    const SizedBox(width: 8),
                    _StakeholderChip(icon: Icons.traffic_rounded, color: Colors.amber),
                    const SizedBox(width: 8),
                    _StakeholderChip(icon: Icons.campaign_rounded, color: Colors.cyanAccent),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final CrisisStatus status;
  final Color color;

  const _StatusBadge({required this.status, required this.color});

  @override
  Widget build(BuildContext context) {
    String text;
    Color bg;
    Color tc;
    bool blink = false;

    if (status == CrisisStatus.active) {
      text = 'ACTIVE'; bg = accentCritical; tc = accentCritical; blink = true;
    } else if (status == CrisisStatus.monitoring) {
      text = 'MONITORING'; bg = accentWarning; tc = accentWarning;
    } else {
      text = 'RESOLVED'; bg = accentSafe; tc = accentSafe;
    }

    Widget badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text, style: inter(10, weight: FontWeight.w700, color: tc, letterSpacing: 1)),
    );

    if (blink) {
      return badge.animate(onPlay: (c) => c.repeat())
        .then(delay: 400.ms).fadeOut(duration: 400.ms)
        .then().fadeIn(duration: 400.ms);
    }
    return badge;
  }
}

class _StakeholderChip extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _StakeholderChip({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
    child: Icon(icon, size: 14, color: color),
  );
}

// Modal Details

class _CrisisDetailModal extends StatelessWidget {
  final Crisis crisis;
  final ResourceAllocation? allocation;

  const _CrisisDetailModal({required this.crisis, this.allocation});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: bgPrimary.withOpacity(0.95),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: accentInfo.withOpacity(0.2)),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(20),
              children: [
                Center(
                  child: Container(width: 40, height: 4, decoration: BoxDecoration(color: surfaceLight, borderRadius: BorderRadius.circular(2))),
                ),
                const SizedBox(height: 20),
                Text('CRISIS DETAILS', style: syne(22, color: accentInfo, weight: FontWeight.w700)),
                const SizedBox(height: 16),
                
                // Cascade Effects
                Text('ALL CASCADE EFFECTS', style: inter(12, color: textSecondary, weight: FontWeight.w600)),
                const SizedBox(height: 8),
                ...crisis.cascadeEffects.map((c) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.arrow_right_rounded, color: accentWarning, size: 16),
                      Expanded(child: Text(c, style: inter(13, color: textPrimary))),
                    ],
                  ),
                )),
                const SizedBox(height: 20),

                // Resources
                if (allocation != null) ...[
                  Text('RESOURCE ASSIGNMENT', style: inter(12, color: textSecondary, weight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  GlassCard(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _ResVal(Icons.local_hospital_rounded, allocation!.resourcesAssigned.ambulances, 'AMB', accentCritical),
                        _ResVal(Icons.groups_rounded, allocation!.resourcesAssigned.rescueTeams, 'RES', accentWarning),
                        _ResVal(Icons.local_police_rounded, allocation!.resourcesAssigned.policeUnits, 'POL', accentInfo),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Actions
                  Text('ACTION TIMELINE', style: inter(12, color: textSecondary, weight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  ...allocation!.actions.map((a) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GlassCard(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(a.description, style: inter(13, color: textPrimary)),
                          Text(a.stateChange, style: inter(11, color: textSecondary)),
                        ],
                      ),
                    ),
                  )),
                  const SizedBox(height: 20),

                  // Stakeholder Messages
                  Text('STAKEHOLDER MESSAGES', style: inter(12, color: textSecondary, weight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  _MsgExpandable(title: 'Public (EN)', body: allocation!.stakeholderMessages.publicEnglish, color: Colors.cyanAccent),
                  _MsgExpandable(title: 'Public (UR)', body: allocation!.stakeholderMessages.publicUrdu, color: Colors.cyanAccent),
                  _MsgExpandable(title: 'Hospital', body: allocation!.stakeholderMessages.pimsHospital, color: Colors.pinkAccent),
                  _MsgExpandable(title: 'Traffic', body: allocation!.stakeholderMessages.trafficAuthority, color: Colors.amber),
                  const SizedBox(height: 20),
                ],

                // Comparison Table
                Text('BEFORE / AFTER COMPARISON', style: inter(12, color: textSecondary, weight: FontWeight.w600)),
                const SizedBox(height: 8),
                GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text('METRIC', style: inter(10, color: textSecondary))),
                          Expanded(child: Text('BEFORE', style: inter(10, color: accentCritical, weight: FontWeight.w700))),
                          Expanded(child: Text('AFTER', style: inter(10, color: accentSafe, weight: FontWeight.w700))),
                        ],
                      ),
                      const Divider(color: surfaceLight),
                      _CompRow('Response Time', '15 min', '4 min'),
                      _CompRow('Congestion', 'Severe', 'Rerouted'),
                      _CompRow('Unallocated', '3 events', '0 events'),
                      _CompRow('Specificity', 'Low', 'High'),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ResVal extends StatelessWidget {
  final IconData icon;
  final int val;
  final String label;
  final Color color;
  const _ResVal(this.icon, this.val, this.label, this.color);

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Icon(icon, color: val > 0 ? color : textSecondary),
      Text('$val', style: syne(20, color: val > 0 ? color : textSecondary, weight: FontWeight.w700)),
      Text(label, style: inter(10, color: textSecondary)),
    ],
  );
}

class _MsgExpandable extends StatelessWidget {
  final String title;
  final String body;
  final Color color;
  const _MsgExpandable({required this.title, required this.body, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    decoration: BoxDecoration(
      color: surfaceLight.withOpacity(0.5),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: ExpansionTile(
      title: Text(title, style: inter(13, color: color, weight: FontWeight.w600)),
      childrenPadding: const EdgeInsets.all(12),
      children: [Text(body, style: inter(12, color: textPrimary))],
    ),
  );
}

class _CompRow extends StatelessWidget {
  final String metric, before, after;
  const _CompRow(this.metric, this.before, this.after);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Expanded(child: Text(metric, style: inter(12, color: textSecondary))),
        Expanded(child: Text(before, style: inter(12, color: accentCritical))),
        Expanded(child: Text(after, style: inter(12, color: accentSafe))),
      ],
    ),
  );
}
