// lib/models/crisis_state.dart
// CIRO — Crisis Intelligence & Response Orchestrator
// Mirrors the JSON output structure from all 4 simulation scenarios.

class CrisisState {
  final String simulationTime;
  final String scenario;
  final bool degradedMode;
  final AgentTraces agentTraces;
  final FinalState finalState;
  final ApiFailureInfo? apiFailure;

  const CrisisState({
    required this.simulationTime,
    required this.scenario,
    required this.degradedMode,
    required this.agentTraces,
    required this.finalState,
    this.apiFailure,
  });

  static Map<String, dynamic> _safeMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  factory CrisisState.fromJson(Map<String, dynamic> json) {
    return CrisisState(
      simulationTime: json['simulation_time'] as String? ?? '',
      scenario: json['scenario'] as String? ?? '',
      degradedMode: json['final_state']?['degraded_mode'] as bool? ?? false,
      agentTraces: AgentTraces.fromJson(_safeMap(json['agent_traces'])),
      finalState: FinalState.fromJson(_safeMap(json['final_state'])),
      apiFailure: json['api_failure'] != null
          ? ApiFailureInfo.fromJson(_safeMap(json['api_failure']))
          : null,
    );
  }
}

// ─── Agent Traces ───────────────────────────────────────────────────────────

class AgentTraces {
  final Agent1Fusion agent1;
  final Agent2Detection agent2;
  final Agent3Allocation agent3;

  const AgentTraces({
    required this.agent1,
    required this.agent2,
    required this.agent3,
  });

  factory AgentTraces.fromJson(Map<String, dynamic> json) {
    return AgentTraces(
      agent1: Agent1Fusion.fromJson(CrisisState._safeMap(json['agent1_signal_fusion'])),
      agent2: Agent2Detection.fromJson(CrisisState._safeMap(json['agent2_crisis_detection'])),
      agent3: Agent3Allocation.fromJson(CrisisState._safeMap(json['agent3_resource_allocation'])),
    );
  }
}

class Agent1Fusion {
  final List<String> steps;
  final List<FusedSignal> fusedSignals;

  const Agent1Fusion({required this.steps, required this.fusedSignals});

  factory Agent1Fusion.fromJson(Map<String, dynamic> json) {
    return Agent1Fusion(
      steps: List<String>.from(json['steps'] as List? ?? []),
      fusedSignals: (json['fused_signals'] as List? ?? [])
          .map((e) => FusedSignal.fromJson(CrisisState._safeMap(e)))
          .toList(),
    );
  }
}

class Agent2Detection {
  final List<String> steps;
  final List<Crisis> crises;

  const Agent2Detection({required this.steps, required this.crises});

  factory Agent2Detection.fromJson(Map<String, dynamic> json) {
    return Agent2Detection(
      steps: List<String>.from(json['steps'] as List? ?? []),
      crises: (json['crises'] as List? ?? [])
          .map((e) => Crisis.fromJson(CrisisState._safeMap(e)))
          .toList(),
    );
  }
}

class Agent3Allocation {
  final List<String> steps;
  final List<ResourceAllocation> allocations;

  const Agent3Allocation({required this.steps, required this.allocations});

  factory Agent3Allocation.fromJson(Map<String, dynamic> json) {
    return Agent3Allocation(
      steps: List<String>.from(json['steps'] as List? ?? []),
      allocations: (json['allocations'] as List? ?? [])
          .map((e) => ResourceAllocation.fromJson(CrisisState._safeMap(e)))
          .toList(),
    );
  }
}

// ─── Core Data Models ────────────────────────────────────────────────────────

class FusedSignal {
  final String location;
  final String eventType;
  final double credibilityScore;
  final int sourceCount;
  final int mentionVelocity;
  final List<String> sourceTypes;
  final bool corroborated;
  final String? overrideNote;
  final String? dataQualityNote;

  const FusedSignal({
    required this.location,
    required this.eventType,
    required this.credibilityScore,
    required this.sourceCount,
    required this.mentionVelocity,
    required this.sourceTypes,
    required this.corroborated,
    this.overrideNote,
    this.dataQualityNote,
  });

  factory FusedSignal.fromJson(Map<String, dynamic> json) {
    return FusedSignal(
      location: json['location'] as String? ?? 'Unknown',
      eventType: json['event_type'] as String? ?? 'unknown',
      credibilityScore: (json['credibility_score'] as num?)?.toDouble() ?? 0.5,
      sourceCount: json['source_count'] as int? ?? 1,
      mentionVelocity: json['mention_velocity'] as int? ?? 0,
      sourceTypes: List<String>.from(json['source_types'] as List? ?? []),
      corroborated: json['corroborated'] as bool? ?? false,
      overrideNote: json['override_note'] as String?,
      dataQualityNote: json['data_quality_note'] as String?,
    );
  }
}

class Crisis {
  final String id;
  final String type;
  final String? subtype;
  final String location;
  final double? severity;
  final double confidence;
  final double? affectedRadiusKm;
  final List<String> cascadeEffects;
  final CrisisStatus status;
  final String? reclassifiedFrom;
  final String? reclassificationReason;
  final String? escalationNote;
  final String? dataQualityWarning;

  const Crisis({
    required this.id,
    required this.type,
    this.subtype,
    required this.location,
    this.severity,
    required this.confidence,
    this.affectedRadiusKm,
    required this.cascadeEffects,
    required this.status,
    this.reclassifiedFrom,
    this.reclassificationReason,
    this.escalationNote,
    this.dataQualityWarning,
  });

  factory Crisis.fromJson(Map<String, dynamic> json) {
    return Crisis(
      id: json['id']?.toString() ?? 'crisis_${DateTime.now().millisecondsSinceEpoch}',
      type: json['type'] as String? ?? 'unknown',
      subtype: json['subtype'] as String?,
      location: json['location'] as String? ?? 'Unknown',
      severity: (json['severity'] as num?)?.toDouble(),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.5,
      affectedRadiusKm: (json['affected_radius_km'] as num?)?.toDouble(),
      cascadeEffects: List<String>.from(json['cascade_effects'] as List? ?? []),
      status: CrisisStatus.fromString(json['status'] as String? ?? 'MONITORING'),
      reclassifiedFrom: json['reclassified_from'] as String?,
      reclassificationReason: json['reclassification_reason'] as String?,
      escalationNote: json['escalation_note'] as String?,
      dataQualityWarning: json['data_quality_warning'] as String?,
    );
  }

  bool get isActive => status == CrisisStatus.active;
  bool get isMonitoring => status == CrisisStatus.monitoring;
}

enum CrisisStatus {
  active,
  monitoring,
  retracted;

  static CrisisStatus fromString(String s) {
    switch (s.toUpperCase()) {
      case 'ACTIVE':
        return CrisisStatus.active;
      case 'MONITORING':
        return CrisisStatus.monitoring;
      case 'RETRACTED':
        return CrisisStatus.retracted;
      default:
        return CrisisStatus.monitoring;
    }
  }
}

// ─── Resource Allocation ─────────────────────────────────────────────────────

class ResourceAllocation {
  final String crisisId;
  final double priorityScore;
  final ResourceBundle resourcesAssigned;
  final List<CrisisAction> actions;
  final StakeholderMessages stakeholderMessages;

  const ResourceAllocation({
    required this.crisisId,
    required this.priorityScore,
    required this.resourcesAssigned,
    required this.actions,
    required this.stakeholderMessages,
  });

  factory ResourceAllocation.fromJson(Map<String, dynamic> json) {
    return ResourceAllocation(
      crisisId: json['crisis_id']?.toString() ?? 'unknown',
      priorityScore: (json['priority_score'] as num?)?.toDouble() ?? 0.0,
      resourcesAssigned: ResourceBundle.fromJson(
          CrisisState._safeMap(json['resources_assigned'])),
      actions: (json['actions'] as List? ?? [])
          .map((e) => CrisisAction.fromJson(CrisisState._safeMap(e)))
          .toList(),
      stakeholderMessages: StakeholderMessages.fromJson(
          CrisisState._safeMap(json['stakeholder_messages'])),
    );
  }
}

class ResourceBundle {
  final int ambulances;
  final int rescueTeams;
  final int policeUnits;
  final int medicalVans;

  const ResourceBundle({
    required this.ambulances,
    required this.rescueTeams,
    required this.policeUnits,
    required this.medicalVans,
  });

  factory ResourceBundle.fromJson(Map<String, dynamic> json) {
    return ResourceBundle(
      ambulances: json['ambulances'] as int? ?? 0,
      rescueTeams: json['rescue_teams'] as int? ?? 0,
      policeUnits: json['police_units'] as int? ?? 0,
      medicalVans: json['medical_vans'] as int? ?? 0,
    );
  }

  int get total => ambulances + rescueTeams + policeUnits + medicalVans;
}

class CrisisAction {
  final String description;
  final String stateChange;

  const CrisisAction({required this.description, required this.stateChange});

  factory CrisisAction.fromJson(Map<String, dynamic> json) {
    return CrisisAction(
      description: json['description'] as String? ?? '',
      stateChange: json['state_change'] as String? ?? '',
    );
  }
}

class StakeholderMessages {
  final String publicEnglish;
  final String publicUrdu;
  final String pimsHospital;
  final String trafficAuthority;
  final String iescoutility;
  final String mediaCommand;

  const StakeholderMessages({
    required this.publicEnglish,
    required this.publicUrdu,
    required this.pimsHospital,
    required this.trafficAuthority,
    required this.iescoutility,
    required this.mediaCommand,
  });

  factory StakeholderMessages.fromJson(Map<String, dynamic> json) {
    return StakeholderMessages(
      publicEnglish: json['public_english'] as String? ?? '',
      publicUrdu: json['public_urdu'] as String? ?? '',
      pimsHospital: json['pims_hospital'] as String? ?? '',
      trafficAuthority: json['traffic_authority'] as String? ?? '',
      iescoutility: json['iesco_utility'] as String? ?? '',
      mediaCommand: json['media_command'] as String? ?? '',
    );
  }
}

// ─── Final State ─────────────────────────────────────────────────────────────

class FinalState {
  final List<Crisis> activeCrises;
  final List<Crisis> monitoringEvents;
  final List<AllocationSummary> allocations;
  final ResourceBundle resourcePoolRemaining;
  final List<String> pendingAlerts;
  final List<String> retractedAlerts;
  final List<SystemWarning> systemWarnings;
  final bool degradedMode;

  const FinalState({
    required this.activeCrises,
    required this.monitoringEvents,
    required this.allocations,
    required this.resourcePoolRemaining,
    required this.pendingAlerts,
    required this.retractedAlerts,
    required this.systemWarnings,
    required this.degradedMode,
  });

  factory FinalState.fromJson(Map<String, dynamic> json) {
    return FinalState(
      activeCrises: (json['active_crises'] as List? ?? [])
          .map((e) => Crisis.fromJson(CrisisState._safeMap(e)))
          .toList(),
      monitoringEvents: (json['monitoring_events'] as List? ?? [])
          .map((e) => Crisis.fromJson({
                'id': e['id'],
                'type': e['type'],
                'location': e['location'],
                'severity': null,
                'confidence': e['confidence'],
                'affected_radius_km': null,
                'cascade_effects': [],
                'status': e['status'],
              }))
          .toList(),
      allocations: (json['allocations'] as List? ?? [])
          .map((e) => AllocationSummary.fromJson(CrisisState._safeMap(e)))
          .toList(),
      resourcePoolRemaining: ResourceBundle.fromJson(
          CrisisState._safeMap(json['resource_pool_remaining'])),
      pendingAlerts: List<String>.from(json['pending_alerts'] as List? ?? []),
      retractedAlerts: List<String>.from(json['retracted_alerts'] as List? ?? []),
      systemWarnings: (json['system_warnings'] as List? ?? [])
          .map((e) => SystemWarning.fromJson(CrisisState._safeMap(e)))
          .toList(),
      degradedMode: json['degraded_mode'] as bool? ?? false,
    );
  }
}

class AllocationSummary {
  final String crisisId;
  final int ambulances;
  final int rescueTeams;
  final int policeUnits;
  final int medicalVans;

  const AllocationSummary({
    required this.crisisId,
    required this.ambulances,
    required this.rescueTeams,
    required this.policeUnits,
    required this.medicalVans,
  });

  factory AllocationSummary.fromJson(Map<String, dynamic> json) {
    return AllocationSummary(
      crisisId: json['crisis_id']?.toString() ?? 'unknown',
      ambulances: json['ambulances'] as int? ?? 0,
      rescueTeams: json['rescue_teams'] as int? ?? 0,
      policeUnits: json['police_units'] as int? ?? 0,
      medicalVans: json['medical_vans'] as int? ?? 0,
    );
  }
}

class SystemWarning {
  final String type;
  final String source;
  final String impact;

  const SystemWarning({
    required this.type,
    required this.source,
    required this.impact,
  });

  factory SystemWarning.fromJson(Map<String, dynamic> json) {
    return SystemWarning(
      type: json['type']?.toString() ?? json['message']?.toString() ?? 'UNKNOWN',
      source: json['source']?.toString() ?? 'system',
      impact: json['impact']?.toString() ?? json['message']?.toString() ?? 'Unknown impact',
    );
  }
}

// ─── API Failure Info ─────────────────────────────────────────────────────────

class ApiFailureInfo {
  final int signalId;
  final String source;
  final String reason;
  final String fallback;
  final String cachedValue;

  const ApiFailureInfo({
    required this.signalId,
    required this.source,
    required this.reason,
    required this.fallback,
    required this.cachedValue,
  });

  factory ApiFailureInfo.fromJson(Map<String, dynamic> json) {
    return ApiFailureInfo(
      signalId: json['signal_id'] as int? ?? 0,
      source: json['source']?.toString() ?? 'system',
      reason: json['reason']?.toString() ?? 'Unknown reason',
      fallback: json['fallback']?.toString() ?? '',
      cachedValue: json['cached_value']?.toString() ?? '',
    );
  }
}
