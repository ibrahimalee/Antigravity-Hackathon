import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/crisis_state.dart';
import '../services/groq_service.dart';

// State providers map directly to the notifier to maintain backward compatibility
final groqServiceProvider = Provider((ref) => GroqService());

final crisisProvider = StateNotifierProvider<CrisisNotifier, CrisisAppState>((ref) {
  return CrisisNotifier(ref.read(groqServiceProvider));
});

// Derived compatibility providers
final currentCrisisStateProvider = Provider<AsyncValue<CrisisState?>>((ref) {
  final appState = ref.watch(crisisProvider);
  if (appState.isLoading) {
    return const AsyncValue.loading();
  }
  if (appState.errorMessage != null) {
    return AsyncValue.error(appState.errorMessage!, StackTrace.current);
  }
  return AsyncValue.data(appState.currentState);
});

final simulationPhaseProvider = Provider<SimulationPhase>((ref) {
  return ref.watch(crisisProvider).phase;
});

final simulationLogsProvider = StateProvider<List<String>>((ref) => []);

final activeSignalsProvider = Provider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(crisisProvider).signalFeed;
});

final countdownProvider = StreamProvider<int>((ref) {
  return ref.watch(crisisProvider.notifier).countdownStream;
});

enum SimulationPhase { idle, phase1, phase2, phase3, phase4, finished }

class CrisisAppState {
  final SimulationPhase phase;        // idle, phase1, phase2, phase3, phase4, finished
  final bool isLoading;               // true while Groq is processing
  final CrisisState? currentState;    // latest data from Groq
  final List<CrisisState> history;    // all previous states for timeline
  final List<Map<String, dynamic>> signalFeed;  // all signals seen so far (for UI)
  final String? errorMessage;
  final int currentPhaseNumber;       // 0-4
  final String currentPhaseLabel;
  final bool degradedMode;
  final String? tradeoffRationale;    // populated during multi-crisis phase

  const CrisisAppState({
    required this.phase,
    required this.isLoading,
    this.currentState,
    required this.history,
    required this.signalFeed,
    this.errorMessage,
    required this.currentPhaseNumber,
    required this.currentPhaseLabel,
    required this.degradedMode,
    this.tradeoffRationale,
  });

  factory CrisisAppState.initial() {
    return const CrisisAppState(
      phase: SimulationPhase.idle,
      isLoading: false,
      currentState: null,
      history: [],
      signalFeed: [],
      errorMessage: null,
      currentPhaseNumber: 0,
      currentPhaseLabel: 'Awaiting Simulation',
      degradedMode: false,
      tradeoffRationale: null,
    );
  }

  CrisisAppState copyWith({
    SimulationPhase? phase,
    bool? isLoading,
    CrisisState? currentState,
    List<CrisisState>? history,
    List<Map<String, dynamic>>? signalFeed,
    String? errorMessage,
    int? currentPhaseNumber,
    String? currentPhaseLabel,
    bool? degradedMode,
    String? tradeoffRationale,
  }) {
    return CrisisAppState(
      phase: phase ?? this.phase,
      isLoading: isLoading ?? this.isLoading,
      currentState: currentState ?? this.currentState,
      history: history ?? this.history,
      signalFeed: signalFeed ?? this.signalFeed,
      errorMessage: errorMessage ?? this.errorMessage,
      currentPhaseNumber: currentPhaseNumber ?? this.currentPhaseNumber,
      currentPhaseLabel: currentPhaseLabel ?? this.currentPhaseLabel,
      degradedMode: degradedMode ?? this.degradedMode,
      tradeoffRationale: tradeoffRationale ?? this.tradeoffRationale,
    );
  }
}

class CrisisNotifier extends StateNotifier<CrisisAppState> {
  final GroqService _groqService;
  final StreamController<int> _countdownController = StreamController<int>.broadcast();
  
  Map<String, dynamic>? _lastRawState;
  bool _isCancelled = false;

  CrisisNotifier(this._groqService) : super(CrisisAppState.initial());

  Stream<int> get countdownStream => _countdownController.stream;

  @override
  void dispose() {
    _isCancelled = true;
    _countdownController.close();
    super.dispose();
  }

  void resetSimulation() {
    _isCancelled = true;
    _lastRawState = null;
    state = CrisisAppState.initial();
  }

  Future<void> startSimulation() async {
    _isCancelled = false;
    resetSimulation();
    _isCancelled = false;

    // --- PHASE 1 (T+0s) ---
    if (_isCancelled) return;
    state = state.copyWith(
      phase: SimulationPhase.phase1,
      isLoading: true,
      currentPhaseNumber: 1,
      currentPhaseLabel: "Phase 1: Urban Flood — G-10",
      errorMessage: null,
    );

    try {
      final signals = initialSignals;
      const scenario = "Phase 1: Initial flood signals detected in G-10 sector. Three social reports in Roman Urdu, confirmed by weather API (68mm/hr rainfall) and Srinagar Highway traffic congestion at 83%. Run full 3-agent pipeline. Assign emergency resources.";
      
      final rawResult = await _groqService.runAgentPipeline(
        signals: signals,
        scenario: scenario,
        previousState: null,
      );
      
      if (_isCancelled) return;
      _lastRawState = rawResult;
      final parsed = CrisisState.fromJson(rawResult);

      state = state.copyWith(
        isLoading: false,
        currentState: parsed,
        history: [...state.history, parsed],
        signalFeed: [...state.signalFeed, ...signals],
        degradedMode: parsed.finalState.degradedMode,
      );
    } catch (e) {
      if (_isCancelled) return;
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }

    await _runCountdown(12);

    // --- PHASE 2 (T+12s) ---
    if (_isCancelled) return;
    state = state.copyWith(
      phase: SimulationPhase.phase2,
      isLoading: true,
      currentPhaseNumber: 2,
      currentPhaseLabel: "Phase 2: Multi-Crisis — Murree Road",
      errorMessage: null,
    );

    try {
      final signals = [...initialSignals, ...secondCrisisSignals];
      const scenario = "Phase 2: NEW CRISIS — Multi-vehicle accident on Murree Road near Faizabad. Murree Road now has 3 signals including a field report with 0.85 credibility (Rescue 1122 confirmed 2 injured, ambulance required immediately). Fused confidence for Murree Road is 0.72, which EXCEEDS the 0.60 activation threshold. Classify Murree Road as ACTIVE with severity 6.5. System is already managing G-10 flood (2 ambulances, 1 rescue team deployed). You now have TWO active crises competing for limited resources. Show the explicit trade-off: move 1 ambulance from G-10 to Murree Road, justify why. Write explicit trade-off rationale explaining the resource rebalancing decision. Both crises must appear in active_crises.";
      
      final rawResult = await _groqService.runAgentPipeline(
        signals: signals,
        scenario: scenario,
        previousState: _lastRawState,
      );
      
      if (_isCancelled) return;
      _lastRawState = rawResult;
      final parsed = CrisisState.fromJson(rawResult);

      String? rationale;
      if (parsed.agentTraces.agent3.steps.isNotEmpty) {
        rationale = parsed.agentTraces.agent3.steps.firstWhere(
          (step) => step.toLowerCase().contains('trade-off') || step.toLowerCase().contains('reallocat'),
          orElse: () => parsed.agentTraces.agent3.steps.join('\n'),
        );
      }

      state = state.copyWith(
        isLoading: false,
        currentState: parsed,
        history: [...state.history, parsed],
        signalFeed: [...state.signalFeed, ...secondCrisisSignals],
        degradedMode: parsed.finalState.degradedMode,
        tradeoffRationale: rationale,
      );
    } catch (e) {
      if (_isCancelled) return;
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }

    await _runCountdown(12);

    // --- PHASE 3 (T+24s) ---
    if (_isCancelled) return;
    state = state.copyWith(
      phase: SimulationPhase.phase3,
      isLoading: true,
      currentPhaseNumber: 3,
      currentPhaseLabel: "Phase 3: False Alarm Retraction",
      errorMessage: null,
    );

    try {
      final signals = [...initialSignals, ...secondCrisisSignals, ...fieldReportSignal];
      const scenario = "Phase 3: FIELD VERIFICATION REPORT received — G-10 flooding was actually a burst water main at G-10/2, NOT surface flooding. Reclassify G-10 crisis from FLOOD to INFRASTRUCTURE_FAILURE. Set status to RETRACTED. Return deployed ambulance and rescue team to standby. Generate retraction message to public. Murree Road accident remains ACTIVE.";
      
      final rawResult = await _groqService.runAgentPipeline(
        signals: signals,
        scenario: scenario,
        previousState: _lastRawState,
      );
      
      if (_isCancelled) return;
      _lastRawState = rawResult;
      final parsed = CrisisState.fromJson(rawResult);

      state = state.copyWith(
        isLoading: false,
        currentState: parsed,
        history: [...state.history, parsed],
        signalFeed: [...state.signalFeed, ...fieldReportSignal],
        degradedMode: parsed.finalState.degradedMode,
      );
    } catch (e) {
      if (_isCancelled) return;
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }

    await _runCountdown(12);

    // --- PHASE 4 (T+36s) ---
    if (_isCancelled) return;
    state = state.copyWith(
      phase: SimulationPhase.phase4,
      isLoading: true,
      currentPhaseNumber: 4,
      currentPhaseLabel: "Phase 4: API Failure / Degraded Mode",
      errorMessage: null,
    );

    try {
      final weatherOfflineSignal = {
        "id": 10,
        "source": "sensor",
        "text": "Telemetry alert: Weather API offline. Connection timeout.",
        "location_hint": "System",
        "timestamp": "11:00",
        "base_credibility": 0.0
      };
      
      final signals = [...initialSignals, ...secondCrisisSignals, ...fieldReportSignal, weatherOfflineSignal];
      const scenario = "Phase 4: Weather API has gone OFFLINE. Signal Fusion agent must use cached rainfall data (68mm/hr from 8 minutes ago). Reduce weather signal credibility by -0.15 to reflect telemetry decay. Set degraded_mode=true in final_state. Set api_failure object with source=weather_api, reason=connection_timeout, fallback=cached_data, cached_value=68mm/hr. Murree Road accident remains being managed. Set a system_warning.";
      
      final rawResult = await _groqService.runAgentPipeline(
        signals: signals,
        scenario: scenario,
        previousState: _lastRawState,
      );
      
      if (_isCancelled) return;
      _lastRawState = rawResult;
      final parsed = CrisisState.fromJson(rawResult);

      state = state.copyWith(
        phase: SimulationPhase.finished,
        isLoading: false,
        currentState: parsed,
        history: [...state.history, parsed],
        signalFeed: [...state.signalFeed, weatherOfflineSignal],
        degradedMode: parsed.finalState.degradedMode,
      );
    } catch (e) {
      if (_isCancelled) return;
      state = state.copyWith(
        phase: SimulationPhase.finished,
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> _runCountdown(int seconds) async {
    for (int i = seconds; i >= 0; i--) {
      if (_isCancelled) return;
      _countdownController.add(i);
      await Future.delayed(const Duration(seconds: 1));
    }
  }

  Future<void> injectCrisis(String type, String location) async {
    final newSignal = {
      "id": DateTime.now().millisecondsSinceEpoch,
      "source": "field_report",
      "text": "CRITICAL INCIDENT: Dynamic injection of crisis of type $type detected at $location.",
      "location_hint": location,
      "timestamp": "11:05",
      "base_credibility": 0.95
    };

    final updatedSignals = [...state.signalFeed, newSignal];
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final scenario = "Dynamic Injection: A new incident of type $type is reported at $location. Analyze signal immediately, check for cascading impacts, assign resources and establish incident command.";
      final rawResult = await _groqService.runAgentPipeline(
        signals: updatedSignals,
        scenario: scenario,
        previousState: _lastRawState,
      );

      _lastRawState = rawResult;
      final parsed = CrisisState.fromJson(rawResult);

      state = state.copyWith(
        isLoading: false,
        currentState: parsed,
        history: [...state.history, parsed],
        signalFeed: updatedSignals,
        degradedMode: parsed.finalState.degradedMode,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> submitFieldReport(bool confirm) async {
    if (!confirm) {
      // Trigger false alarm retraction scenario immediately
      state = state.copyWith(
        phase: SimulationPhase.phase3,
        isLoading: true,
        currentPhaseNumber: 3,
        currentPhaseLabel: "Field Report: G-10 Water Main Retraction",
        errorMessage: null,
      );

      try {
        final signals = [...state.signalFeed, ...fieldReportSignal];
        const scenario = "Field Verification: Retract G-10 urban flooding. It is confirmed as a localized burst water main. Demobilize emergency teams and notify municipal repair dispatch.";
        
        final rawResult = await _groqService.runAgentPipeline(
          signals: signals,
          scenario: scenario,
          previousState: _lastRawState,
        );

        _lastRawState = rawResult;
        final parsed = CrisisState.fromJson(rawResult);

        state = state.copyWith(
          isLoading: false,
          currentState: parsed,
          history: [...state.history, parsed],
          signalFeed: [...state.signalFeed, ...fieldReportSignal],
          degradedMode: parsed.finalState.degradedMode,
        );
      } catch (e) {
        state = state.copyWith(isLoading: false, errorMessage: e.toString());
      }
    }
  }

  void submitCommanderOverride(String crisisId, String rationale, double severity, int ambDelta, int resDelta, int polDelta) {
    if (_lastRawState == null) return;
    
    // Deep clone by round-tripping JSON
    final jsonClone = jsonDecode(jsonEncode(_lastRawState));
    
    // 1. Modify the crisis severity
    final crises = jsonClone['agent_traces']?['agent2_crisis_detection']?['crises'] as List?;
    if (crises != null) {
      for (var c in crises) {
        if (c['id'] == crisisId) {
          c['severity'] = severity;
        }
      }
    }
    
    final finalCrises = jsonClone['final_state']?['active_crises'] as List?;
    if (finalCrises != null) {
      for (var c in finalCrises) {
        if (c['id'] == crisisId) {
          c['severity'] = severity;
        }
      }
    }

    // 2. Modify resource allocations
    final allocs = jsonClone['agent_traces']?['agent3_resource_allocation']?['allocations'] as List?;
    if (allocs != null) {
      for (var a in allocs) {
        if (a['crisis_id'] == crisisId) {
          a['resources_assigned']['ambulances'] = (a['resources_assigned']['ambulances'] ?? 0) + ambDelta;
          a['resources_assigned']['rescue_teams'] = (a['resources_assigned']['rescue_teams'] ?? 0) + resDelta;
          a['resources_assigned']['police_units'] = (a['resources_assigned']['police_units'] ?? 0) + polDelta;
        }
      }
    }
    
    final finalAllocs = jsonClone['final_state']?['allocations'] as List?;
    if (finalAllocs != null) {
      for (var a in finalAllocs) {
        if (a['crisis_id'] == crisisId) {
          a['ambulances'] = (a['ambulances'] ?? 0) + ambDelta;
          a['rescue_teams'] = (a['rescue_teams'] ?? 0) + resDelta;
          a['police_units'] = (a['police_units'] ?? 0) + polDelta;
        }
      }
    }

    // 3. Log the Trace
    final steps3 = jsonClone['agent_traces']?['agent3_resource_allocation']?['steps'] as List?;
    if (steps3 != null) {
      final timestamp = DateTime.now().toIso8601String().substring(11, 19);
      steps3.add('[COMMANDER_OVERRIDE] ($timestamp) Severity forced to $severity. Rationale: "$rationale". Adjustments: Amb: ${ambDelta > 0 ? "+$ambDelta" : ambDelta}, Res: ${resDelta > 0 ? "+$resDelta" : resDelta}, Pol: ${polDelta > 0 ? "+$polDelta" : polDelta}');
    }

    _lastRawState = jsonClone;
    final parsed = CrisisState.fromJson(jsonClone);

    state = state.copyWith(
      currentState: parsed,
      history: [...state.history, parsed],
    );
  }
}

// Signals data constants
const initialSignals = [
  {"id": 1, "source": "anonymous_social", "text": "G-10 mein pani bhar gaya hai, gaariyan phans gayi hain", "location_hint": "G-10", "timestamp": "10:42", "base_credibility": 0.35},
  {"id": 2, "source": "anonymous_social", "text": "Sector G-10 main flooding ho rahi hai, please help", "location_hint": "G-10", "timestamp": "10:43", "base_credibility": 0.35},
  {"id": 3, "source": "anonymous_social", "text": "G-10 ki taraf sarak band hai, pani bohat hai", "location_hint": "G-10", "timestamp": "10:44", "base_credibility": 0.35},
  {"id": 4, "source": "weather_api", "text": "Islamabad rainfall 68mm/hr heavy rain alert active", "location_hint": "Islamabad North", "timestamp": "10:45", "base_credibility": 0.90},
  {"id": 5, "source": "traffic_api", "text": "Srinagar Highway congestion 83% near G-10 junction", "location_hint": "G-10", "timestamp": "10:46", "base_credibility": 0.80},
];

const secondCrisisSignals = [
  {"id": 6, "source": "anonymous_social", "text": "Buri tarah accident hua hai Murree Road pe, ek gaari palat gayi", "location_hint": "Murree Road", "timestamp": "10:50", "base_credibility": 0.35},
  {"id": 7, "source": "traffic_api", "text": "Murree Road congestion 72% near Rawalpindi junction, multiple vehicles", "location_hint": "Murree Road", "timestamp": "10:52", "base_credibility": 0.80},
  {"id": 8, "source": "field_report", "text": "Rescue 1122 called to Murree Road near Faizabad: confirmed multi-vehicle collision, 2 injured, ambulance required immediately", "location_hint": "Murree Road", "timestamp": "10:53", "base_credibility": 0.85},
];

const fieldReportSignal = [
  {"id": 9, "source": "field_report", "text": "On-site verification G-10/2: burst water main, NOT surface flooding. Isolated to one block. No rescue needed.", "location_hint": "G-10", "timestamp": "10:58", "base_credibility": 0.85},
];
