import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import '../models/crisis_state.dart';
import 'api_keys.dart';

class GroqService {
  static const List<String> _apiKeys = ApiKeys.keys;

  // Active key used as a fallback for testing when placeholders are not configured
  static const String _fallbackKey = ApiKeys.fallbackKey;
  static const String _endpoint = 'https://api.groq.com/openai/v1/chat/completions';
  
  static bool _useFallback = true;
  static int _keyIndex = 0;

  static String _nextKey() {
    final key = _apiKeys[_keyIndex];
    _keyIndex = (_keyIndex + 1) % _apiKeys.length;
    if (key.startsWith('GROQ_KEY_')) {
      return _fallbackKey;
    }
    return key;
  }

  static int get activeKeyIndex => _keyIndex % _apiKeys.length;
  static int get totalKeys => _apiKeys.length;

  static int getCurrentKeyIndex() {
    return _keyIndex;
  }

  static const String systemPrompt = '''
You are a three-agent crisis intelligence system for Islamabad, Pakistan.
You MUST respond with ONLY valid JSON — no markdown, no explanation, no preamble.
The JSON must exactly match this schema:

{
  "simulation_time": "string HH:mm",
  "scenario": "string describing what happened",
  "agent_traces": {
    "agent1_signal_fusion": {
      "steps": ["step description 1", "step description 2"],
      "fused_signals": [
        {
          "location": "G-10",
          "event_type": "FLOOD",
          "credibility_score": 0.82,
          "source_count": 3,
          "mention_velocity": 3,
          "source_types": ["anonymous_social", "weather_api", "traffic_api"],
          "corroborated": true,
          "override_note": null,
          "data_quality_note": null
        }
      ]
    },
    "agent2_crisis_detection": {
      "steps": ["step description"],
      "crises": [
        {
          "id": "crisis_001",
          "type": "FLOOD",
          "subtype": "urban_flooding",
          "location": "G-10",
          "severity": 8.0,
          "confidence": 0.87,
          "affected_radius_km": 2.5,
          "cascade_effects": ["Traffic displacement to G-9", "ER surge at Polyclinic"],
          "status": "ACTIVE",
          "reclassified_from": null,
          "reclassification_reason": null,
          "escalation_note": null,
          "data_quality_warning": null
        }
      ]
    },
    "agent3_resource_allocation": {
      "steps": ["step description"],
      "allocations": [
        {
          "crisis_id": "crisis_001",
          "priority_score": 12.4,
          "resources_assigned": {
            "ambulances": 2,
            "rescue_teams": 1,
            "police_units": 2,
            "medical_vans": 1
          },
          "actions": [
            {"description": "Dispatch 2 ambulances to G-10", "state_change": "ambulances_deployed"},
            {"description": "Reroute traffic: Srinagar Highway CLOSED, IJP Road OPEN", "state_change": "traffic_rerouted"},
            {"description": "Alert PIMS Hospital: prepare 8 trauma beds", "state_change": "hospital_notified"},
            {"description": "Broadcast public alert", "state_change": "alert_sent"},
            {"description": "Emergency ticket created: #ISB-2026-001", "state_change": "ticket_created"}
          ],
          "stakeholder_messages": {
            "public_english": "EMERGENCY: Severe flooding in G-10. Avoid Srinagar Highway. Use IJP Road alternate route.",
            "public_urdu": "ہنگامی الرٹ: جی-10 میں سیلاب۔ سری نگر ہائی وے سے گریز کریں۔ آئی جے پی روڈ استعمال کریں۔",
            "pims_hospital": "TRAUMA ALERT: Urban flooding G-10. Prepare 8 trauma beds. First ambulance ETA: 12 min.",
            "traffic_authority": "INCIDENT COMMAND: Block Srinagar Highway G-10 junction. Redirect to IJP Road immediately.",
            "iesco_utility": "SAFETY ALERT: Flooding G-10. Electrical hazard risk. Dispatch crew to G-10/2.",
            "media_command": "Incident #ISB-2026-001. Type: Urban Flood. Severity: 8/10. Confidence: 87%. Resources: 2 ambulances deployed."
          }
        }
      ]
    }
  },
  "final_state": {
    "active_crises": [
      {
        "id": "crisis_001",
        "type": "FLOOD",
        "subtype": "urban_flooding",
        "location": "G-10",
        "severity": 8.0,
        "confidence": 0.87,
        "affected_radius_km": 2.5,
        "cascade_effects": ["Traffic displacement to G-9", "ER surge at Polyclinic"],
        "status": "ACTIVE",
        "reclassified_from": null,
        "reclassification_reason": null,
        "escalation_note": null,
        "data_quality_warning": null
      }
    ],
    "monitoring_events": [],
    "allocations": [
      {"crisis_id": "crisis_001", "ambulances": 2, "rescue_teams": 1, "police_units": 2, "medical_vans": 1}
    ],
    "resource_pool_remaining": {
      "ambulances": 2,
      "rescue_teams": 2,
      "police_units": 3,
      "medical_vans": 1
    },
    "pending_alerts": ["Public flood alert for G-10"],
    "retracted_alerts": [],
    "system_warnings": [],
    "degraded_mode": false
  },
  "api_failure": null
}

IMPORTANT RULES:
- crisis status must be exactly: "ACTIVE", "MONITORING", or "RETRACTED"
- severity is a number 1.0-10.0
- confidence is a number 0.0-1.0  
- affected_radius_km is a number in km
- cascade_effects is always an array of strings
- Every field in stakeholder_messages must be a non-empty string
- resource_pool_remaining must always be present with all 4 fields
- If scenario involves a false alarm retraction, set crisis status to "RETRACTED" 
  and populate reclassified_from and reclassification_reason
- If scenario involves API failure, set api_failure object and degraded_mode to true
  in final_state
''';

  Future<Map<String, dynamic>> runAgentPipeline({
    required List<Map<String, dynamic>> signals,
    required String scenario,
    Map<String, dynamic>? previousState,
  }) async {
    final userPrompt = StringBuffer();
    userPrompt.writeln('Scenario: $scenario');
    userPrompt.writeln('Signals: ${jsonEncode(signals)}');
    if (previousState != null) {
      userPrompt.writeln('Previous system state: ${jsonEncode(previousState)}');
    }

    final bodyStr = jsonEncode({
      'model': 'llama-3.3-70b-versatile',
      'messages': [
        {'role': 'system', 'content': systemPrompt},
        {'role': 'user', 'content': userPrompt.toString()}
      ],
      'temperature': 0.1,
      'max_tokens': 6000,
    });

    for (int attempt = 1; attempt <= _apiKeys.length; attempt++) {
      final apiKey = _nextKey();
      print('Groq API call attempt $attempt/${_apiKeys.length} using active index: $activeKeyIndex');
      
      try {
        final response = await http.post(
          Uri.parse(_endpoint),
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
          body: bodyStr,
        ).timeout(const Duration(seconds: 45));
        
        print('Groq Response Code: ${response.statusCode}');
        
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          String content = data['choices'][0]['message']['content'] as String;
          
          try {
            return _parseJsonContent(content);
          } catch (e) {
            print('JSON Parse Error, trying regex extraction: $e');
            final match = RegExp(r'\{[\s\S]*\}').firstMatch(content);
            if (match != null) {
              return jsonDecode(match.group(0)!);
            }
            rethrow;
          }
        } else if (response.statusCode == 429) {
          print('Rate limit (429) encountered at index $activeKeyIndex. Rotating immediately.');
          continue;
        } else {
          throw Exception('Groq API Error (${response.statusCode}): ${response.body}');
        }
      } catch (e) {
        print('Exception on attempt $attempt: $e');
        if (attempt == _apiKeys.length) {
          break;
        }
      }
    }

    print('All keys failed or rate-limited. Waiting 3 seconds before final attempt...');
    await Future.delayed(const Duration(seconds: 3));

    final finalApiKey = _nextKey();
    try {
      final response = await http.post(
        Uri.parse(_endpoint),
        headers: {
          'Authorization': 'Bearer $finalApiKey',
          'Content-Type': 'application/json',
        },
        body: bodyStr,
      ).timeout(const Duration(seconds: 45));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String content = data['choices'][0]['message']['content'] as String;
        try {
          return _parseJsonContent(content);
        } catch (e) {
          final match = RegExp(r'\{[\s\S]*\}').firstMatch(content);
          if (match != null) {
            return jsonDecode(match.group(0)!);
          }
          rethrow;
        }
      } else {
        throw Exception('Groq API Error (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      if (_useFallback) {
        print('Groq API failed. Triggering DEMO RELIABILITY STRATEGY: Loading local JSON cache.');
        return _getFallbackState(scenario);
      }
      return _getErrorStateMap('All Groq API keys rate-limited or failed. Final attempt error: $e');
    }
  }

  Future<Map<String, dynamic>> _getFallbackState(String scenario) async {
    String assetPath = 'assets/fallback_phase1.json';
    final s = scenario.toLowerCase();
    
    // Auto-detect which phase we are in based on the scenario string passed by the provider
    if (s.contains('second') || s.contains('murree')) {
      assetPath = 'assets/fallback_phase2.json';
    } else if (s.contains('field report') || s.contains('verification') || s.contains('water main')) {
      assetPath = 'assets/fallback_phase3.json';
    } else if (s.contains('api failure') || s.contains('weather')) {
      assetPath = 'assets/fallback_phase4.json';
    }
    
    print('Loading fallback asset: $assetPath');
    final jsonStr = await rootBundle.loadString(assetPath);
    final map = jsonDecode(jsonStr);
    
    // Inject the offline mode warning into the agent traces
    if (map['agent_traces'] != null && map['agent_traces']['agent1_signal_fusion'] != null) {
      final steps = List<dynamic>.from(map['agent_traces']['agent1_signal_fusion']['steps'] ?? []);
      steps.insert(0, '[system] WARNING: ⚡ Using cached inference response (offline mode)');
      map['agent_traces']['agent1_signal_fusion']['steps'] = steps;
    }
    return map;
  }

  // Compatibility wrapper for original caller
  Future<CrisisState> processSignals(List<Map<String, dynamic>> signals) async {
    final result = await runAgentPipeline(
      signals: signals,
      scenario: "Dynamic Islamabad Crisis Scenario",
    );
    return CrisisState.fromJson(result);
  }

  Map<String, dynamic> _parseJsonContent(String content) {
    String cleaned = content.trim();
    if (cleaned.contains('```json')) {
      cleaned = cleaned.split('```json')[1].split('```')[0].trim();
    } else if (cleaned.contains('```')) {
      cleaned = cleaned.split('```')[1].split('```')[0].trim();
    }
    return jsonDecode(cleaned);
  }

  Map<String, dynamic> _getErrorStateMap(String errorMessage) {
    return {
      "simulation_time": "10:45",
      "scenario": "error_fallback",
      "agent_traces": {
        "agent1_signal_fusion": {
          "steps": ["Error: $errorMessage"],
          "fused_signals": []
        },
        "agent2_crisis_detection": {
          "steps": ["Error: $errorMessage"],
          "crises": []
        },
        "agent3_resource_allocation": {
          "steps": ["Error: $errorMessage"],
          "allocations": []
        }
      },
      "final_state": {
        "active_crises": [],
        "monitoring_events": [],
        "allocations": [],
        "resource_pool_remaining": {
          "ambulances": 4,
          "rescue_teams": 3,
          "police_units": 5,
          "medical_vans": 2
        },
        "pending_alerts": [],
        "retracted_alerts": [],
        "system_warnings": [
          {"type": "API_FAILURE", "message": errorMessage}
        ],
        "degraded_mode": true
      },
      "api_failure": {
        "message": errorMessage,
        "timestamp": DateTime.now().toIso8601String()
      }
    };
  }
}
