import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
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
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(crisis.severity?.toStringAsFixed(1) ?? '-', style: syne(32, weight: FontWeight.w700, color: accentColor)),
                              Text('/10', style: inter(16, color: textSecondary)),
                            ],
                          ),
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

class _CrisisDetailModal extends ConsumerStatefulWidget {
  final Crisis crisis;
  final ResourceAllocation? allocation;

  const _CrisisDetailModal({required this.crisis, this.allocation});

  @override
  ConsumerState<_CrisisDetailModal> createState() => _CrisisDetailModalState();
}

class _CrisisDetailModalState extends ConsumerState<_CrisisDetailModal> {
  void _showOverrideSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _OverrideCommandSheet(crisis: widget.crisis),
    );
  }

  @override
  Widget build(BuildContext context) {
    final crisis = widget.crisis;
    final allocation = widget.allocation;
    
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('CRISIS DETAILS', style: syne(22, color: accentInfo, weight: FontWeight.w700)),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentWarning.withOpacity(0.15),
                        foregroundColor: accentWarning,
                        side: const BorderSide(color: accentWarning),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      icon: const Icon(Icons.admin_panel_settings_rounded, size: 16),
                      label: Text('OVERRIDE COMMAND', style: inter(10, weight: FontWeight.w700)),
                      onPressed: () => _showOverrideSheet(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Feature 3: Nullah Lai Predictive Risk Layer Chip
                if (crisis.location.toLowerCase().contains('g-10') && crisis.type.toLowerCase().contains('flood')) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blueAccent.withOpacity(0.5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.blueAccent, size: 16),
                        const SizedBox(width: 8),
                        Expanded(child: Text('⚠️ HIGH-RISK ZONE — Nullah Lai corridor. 73% flood recurrence when rainfall exceeds 50mm/hr. Historical reference: July 2023 floods.', style: inter(11, color: Colors.blueAccent, weight: FontWeight.w600))),
                      ],
                    ),
                  ).animate().fadeIn().slideX(),
                ],
                
                // Predictive Timeline
                Text('PREDICTED TIMELINE', style: inter(12, color: textSecondary, weight: FontWeight.w600)),
                _PredictiveTimelineWidget(crisis: crisis),
                const SizedBox(height: 12),

                // Cascade Effects Visualizer
                Text('CRISIS CASCADE CHAIN', style: inter(12, color: textSecondary, weight: FontWeight.w600)),
                const SizedBox(height: 12),
                _CascadeChainWidget(crisis: crisis),
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
                  _StakeholderMessageCard(title: 'Public (EN)', body: allocation!.stakeholderMessages.publicEnglish, color: Colors.cyanAccent, index: 0),
                  _StakeholderMessageCard(title: 'Public (UR)', body: allocation!.stakeholderMessages.publicUrdu, color: Colors.cyanAccent, index: 1, isUrdu: true),
                  _StakeholderMessageCard(title: 'Hospital', body: allocation!.stakeholderMessages.pimsHospital, color: Colors.pinkAccent, index: 2),
                  _StakeholderMessageCard(title: 'Traffic', body: allocation!.stakeholderMessages.trafficAuthority, color: Colors.amber, index: 3),
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

class _StakeholderMessageCard extends StatefulWidget {
  final String title;
  final String body;
  final Color color;
  final int index;
  final bool isUrdu;

  const _StakeholderMessageCard({
    required this.title,
    required this.body,
    required this.color,
    required this.index,
    this.isUrdu = false,
  });

  @override
  State<_StakeholderMessageCard> createState() => _StakeholderMessageCardState();
}

class _StakeholderMessageCardState extends State<_StakeholderMessageCard> {
  final FlutterTts _tts = FlutterTts();
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _tts.setCompletionHandler(() {
      if (mounted) setState(() => _isPlaying = false);
    });
    _tts.setErrorHandler((msg) {
      if (mounted) setState(() => _isPlaying = false);
      debugPrint('TTS Error: $msg');
    });
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  Future<void> _speak() async {
    if (_isPlaying) return;
    setState(() => _isPlaying = true);
    
    // Attempt to set Urdu, but do not block if unsupported
    await _tts.setLanguage('ur-PK');
    await _tts.speak(widget.body);
  }

  @override
  Widget build(BuildContext context) {
    final nowTime = '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: surfaceLight.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: widget.color, width: 4)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.mark_email_read_rounded, size: 14, color: widget.color),
              const SizedBox(width: 6),
              Text(widget.title.toUpperCase(), style: inter(11, color: widget.color, weight: FontWeight.w700)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: accentSafe.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
                child: Text('SENT $nowTime', style: inter(9, color: accentSafe, weight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(widget.body, style: inter(13, color: textPrimary).copyWith(height: widget.isUrdu ? 1.6 : 1.3)),
          if (widget.isUrdu) ...[
            const SizedBox(height: 12),
            InkWell(
              onTap: _isPlaying ? null : _speak,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: widget.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: widget.color.withOpacity(0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_isPlaying ? Icons.volume_up_rounded : Icons.campaign_rounded, size: 16, color: widget.color),
                    const SizedBox(width: 8),
                    Text(_isPlaying ? 'BROADCASTING...' : 'BROADCAST ALERT', style: inter(11, color: widget.color, weight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
          ]
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: (widget.index * 200).ms).slideX(begin: 0.05);
  }
}

class _PredictiveTimelineWidget extends StatelessWidget {
  final Crisis crisis;
  const _PredictiveTimelineWidget({required this.crisis});

  @override
  Widget build(BuildContext context) {
    final isRetracted = crisis.status == CrisisStatus.retracted;
    final nowTime = '10:52';
    final peakTime = '11:15';
    final resolvedTime = isRetracted ? '10:54' : '12:30';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background line
          Positioned(
            left: 20, right: 20, top: 10,
            child: Container(
              height: 2,
              color: isRetracted ? accentSafe.withOpacity(0.5) : surfaceLight,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _TimelineDot('DETECTED', '10:42', true, isRetracted ? accentSafe : accentInfo),
              _TimelineDot('NOW', nowTime, true, isRetracted ? accentSafe : accentInfo),
              _TimelineDot('PEAK', peakTime, !isRetracted, isRetracted ? accentSafe : accentCritical),
              _TimelineDot(isRetracted ? 'RESOLVED' : 'EST RESOLVE', resolvedTime, isRetracted, isRetracted ? accentSafe : textSecondary),
            ],
          ),
        ],
      ),
    );
  }
}

class _TimelineDot extends StatelessWidget {
  final String label, time;
  final bool active;
  final Color color;
  const _TimelineDot(this.label, this.time, this.active, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12, height: 12,
          decoration: BoxDecoration(
            color: active ? color : surface,
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
            boxShadow: active ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 6)] : [],
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: inter(9, color: textSecondary, weight: FontWeight.w600)),
        Text(time, style: inter(10, color: color, weight: FontWeight.w700)),
      ],
    );
  }
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

class _CascadeChainNode {
  final String label;
  final bool isActive;
  
  _CascadeChainNode(this.label, this.isActive);
}

class _CascadeChainWidget extends StatelessWidget {
  final Crisis crisis;
  
  const _CascadeChainWidget({required this.crisis});

  @override
  Widget build(BuildContext context) {
    bool isRetracted = crisis.status == CrisisStatus.retracted;
    bool isFlood = crisis.type.toLowerCase().contains('flood');
    
    List<_CascadeChainNode> nodes = [];
    if (isFlood) {
      nodes = [
        _CascadeChainNode('Urban Flood', true),
        _CascadeChainNode('Srinagar Hwy Blocked', true),
        _CascadeChainNode('G-9 Overflow (+30%)', crisis.status == CrisisStatus.active && crisis.severity != null && crisis.severity! >= 8),
        _CascadeChainNode('PIMS ER Surge (+15%)', false),
        _CascadeChainNode('IESCO Grid Hazard', false),
      ];
    } else {
      nodes = [
        _CascadeChainNode('Road Accident', true),
        _CascadeChainNode('Murree Rd Blocked', true),
        _CascadeChainNode('Rawalpindi Spillover', false),
        _CascadeChainNode('Standby Dispatch', false),
      ];
    }

    return AnimatedSize(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOutCubic,
      child: isRetracted
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: accentSafe.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: accentSafe.withOpacity(0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle_rounded, color: accentSafe, size: 20),
                  const SizedBox(width: 8),
                  Text('INCIDENT CONTAINED & SECURED', style: inter(12, color: accentSafe, weight: FontWeight.w700, letterSpacing: 1.0)),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.9, 0.9))
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  for (int i = 0; i < nodes.length; i++) ...[
                    _buildNode(nodes[i], i),
                    if (i < nodes.length - 1)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: const Icon(Icons.arrow_forward_rounded, color: textSecondary, size: 16)
                            .animate(onPlay: (controller) => controller.repeat())
                            .shimmer(duration: 1500.ms, color: Colors.white54),
                      ),
                  ]
                ],
              ),
            ),
    );
  }

  Widget _buildNode(_CascadeChainNode node, int index) {
    final borderColor = node.isActive ? accentCritical : accentWarning;
    final bgColor = node.isActive ? accentCritical.withOpacity(0.15) : surfaceLight;
    
    Widget chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: node.isActive ? borderColor : borderColor.withOpacity(0.5),
          width: node.isActive ? 1.5 : 1.0,
        ),
      ),
      child: Text(
        node.label,
        style: inter(11, color: node.isActive ? Colors.white : textSecondary, weight: node.isActive ? FontWeight.w600 : FontWeight.w500),
      ),
    );

    if (node.isActive) {
      chip = chip.animate(onPlay: (controller) => controller.repeat(reverse: true))
          .boxShadow(begin: BoxShadow(color: accentCritical.withOpacity(0.0), blurRadius: 0), end: BoxShadow(color: accentCritical.withOpacity(0.4), blurRadius: 8));
    }

    return chip.animate().fadeIn(delay: (index * 100).ms).slideX(begin: 0.1);
  }
}

class _OverrideCommandSheet extends ConsumerStatefulWidget {
  final Crisis crisis;
  const _OverrideCommandSheet({required this.crisis});

  @override
  ConsumerState<_OverrideCommandSheet> createState() => _OverrideCommandSheetState();
}

class _OverrideCommandSheetState extends ConsumerState<_OverrideCommandSheet> {
  final TextEditingController _rationaleController = TextEditingController();
  late double _severity;
  int _ambDelta = 0;
  int _resDelta = 0;
  int _polDelta = 0;

  @override
  void initState() {
    super.initState();
    _severity = widget.crisis.severity ?? 5.0;
  }

  @override
  void dispose() {
    _rationaleController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_rationaleController.text.trim().isEmpty) return;
    
    ref.read(crisisProvider.notifier).submitCommanderOverride(
      widget.crisis.id, 
      _rationaleController.text.trim(), 
      _severity, 
      _ambDelta, 
      _resDelta, 
      _polDelta
    );
    
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.admin_panel_settings_rounded, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text('Override accepted. AI recommendation modified. Rationale logged for audit.', style: inter(13, color: Colors.white, weight: FontWeight.w600))),
          ],
        ),
        backgroundColor: accentWarning,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildDeltaBtn(String label, int val, VoidCallback onInc, VoidCallback onDec) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: inter(13, color: textSecondary)),
        Row(
          children: [
            IconButton(icon: const Icon(Icons.remove_circle_outline, color: accentWarning), onPressed: onDec),
            SizedBox(width: 24, child: Text('${val > 0 ? "+$val" : val}', textAlign: TextAlign.center, style: syne(14, color: textPrimary, weight: FontWeight.w700))),
            IconButton(icon: const Icon(Icons.add_circle_outline, color: accentWarning), onPressed: onInc),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
      decoration: BoxDecoration(
        color: bgPrimary.withOpacity(0.98),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: accentWarning.withOpacity(0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.admin_panel_settings_rounded, color: accentWarning),
              const SizedBox(width: 8),
              Text('COMMANDER OVERRIDE', style: syne(18, color: accentWarning, weight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 16),
          Text('Enter commander rationale (required)', style: inter(11, color: textSecondary)),
          const SizedBox(height: 8),
          TextField(
            controller: _rationaleController,
            style: inter(13, color: textPrimary),
            decoration: InputDecoration(
              filled: true,
              fillColor: surfaceLight,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              hintText: 'e.g. Reprioritizing assets due to real-world context...',
              hintStyle: inter(13, color: textSecondary.withOpacity(0.5)),
            ),
            onChanged: (v) => setState(() {}),
          ),
          const SizedBox(height: 20),
          Text('Severity adjustment: AI says ${widget.crisis.severity?.toStringAsFixed(1) ?? "5.0"}, you say: ${_severity.toStringAsFixed(1)}', style: inter(11, color: textSecondary)),
          Slider(
            value: _severity,
            min: 1.0,
            max: 10.0,
            divisions: 90,
            activeColor: accentWarning,
            onChanged: (v) => setState(() => _severity = v),
          ),
          const SizedBox(height: 16),
          Text('Resource Overrides', style: inter(11, color: textSecondary)),
          const SizedBox(height: 8),
          _buildDeltaBtn('Ambulances', _ambDelta, () => setState(() => _ambDelta++), () => setState(() => _ambDelta--)),
          _buildDeltaBtn('Rescue Teams', _resDelta, () => setState(() => _resDelta++), () => setState(() => _resDelta--)),
          _buildDeltaBtn('Police Units', _polDelta, () => setState(() => _polDelta++), () => setState(() => _polDelta--)),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: accentWarning,
                foregroundColor: bgPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _rationaleController.text.trim().isNotEmpty ? _submit : null,
              child: Text('SUBMIT COMMAND OVERRIDE', style: inter(13, weight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}
