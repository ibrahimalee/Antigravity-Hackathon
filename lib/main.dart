import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart' as intl;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'models/crisis_state.dart';
import 'providers/crisis_provider.dart';
import 'services/groq_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (defaultTargetPlatform == TargetPlatform.android) {
    AndroidGoogleMapsFlutter.useAndroidViewSurface = true;
  }
  runApp(const ProviderScope(child: CiroApp()));
}

class CiroApp extends StatelessWidget {
  const CiroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CIRO — Command Center',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: bgPrimary,
        colorScheme: ColorScheme.fromSeed(seedColor: accentInfo, brightness: Brightness.dark),
      ),
      home: const CrisisMapScreen(),
    );
  }
}

// ── DESIGN SYSTEM CONSTANTS ──────────────────────────────────────────────────
const bgPrimary = Color(0xFF050508);
const bgSecondary = Color(0xFF0D0D14);
const surface = Color(0xFF12121C);
const surfaceLight = Color(0xFF1A1A28);
const textPrimary = Color(0xFFF0F0FF);
const textSecondary = Color(0xFF8888AA);
const accentCritical = Color(0xFFFF4466);
const accentWarning = Color(0xFFFFBF00);
const accentSafe = Color(0xFF00FFB2);
const accentInfo = Color(0xFF00C2FF);
const accentPurple = Color(0xFF7B61FF);

// ── MAP COORDINATES ──────────────────────────────────────────────────────────
const _islamabadCenter = LatLng(33.7215, 73.0433);

const _locations = {
  'G-10': LatLng(33.6938, 73.0229),
  'G-13': LatLng(33.6420, 72.9680),
  'Murree Road': LatLng(33.6631, 73.0844),
  'F-7': LatLng(33.7280, 73.0560),
  'Dhok Hassu': LatLng(33.6300, 73.0800),
  'G-9': LatLng(33.6900, 73.0300),
  'PIMS Hospital': LatLng(33.7130, 73.0580),
  'Srinagar Highway': LatLng(33.6850, 73.0150),
  'Blue Area': LatLng(33.7118, 73.0684),
  'Centaurus Mall': LatLng(33.7077, 73.0498),
  'F-6': LatLng(33.7315, 73.0685),
  'E-11': LatLng(33.7005, 72.9782),
  'G-11': LatLng(33.6841, 72.9986),
  'H-8': LatLng(33.6780, 73.0450),
  'I-9': LatLng(33.6565, 73.0528),
  'Zero Point': LatLng(33.6923, 73.0649),
  'Faizabad': LatLng(33.6631, 73.0844),
};

// ── DARK MAP STYLE ───────────────────────────────────────────────────────────
const _darkMapStyle = '''[
  {"elementType":"geometry","stylers":[{"color":"#050508"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#8888AA"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#050508"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#1A1A28"}]},
  {"featureType":"road","elementType":"geometry.stroke","stylers":[{"color":"#050508"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#1E1E35"}]},
  {"featureType":"road.highway","elementType":"labels.text.fill","stylers":[{"color":"#00C2FF"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#0D1F2D"}]},
  {"featureType":"poi","elementType":"geometry","stylers":[{"color":"#0A0A10"}]},
  {"featureType":"poi.park","elementType":"geometry","stylers":[{"color":"#0A0F0D"}]},
  {"featureType":"transit","elementType":"geometry","stylers":[{"color":"#0D0D14"}]},
  {"featureType":"administrative","elementType":"geometry","stylers":[{"color":"#1A1A28"}]},
  {"featureType":"administrative.locality","elementType":"labels.text.fill","stylers":[{"color":"#00C2FF"}]}
]''';

// ── TYPOGRAPHY UTILITIES ─────────────────────────────────────────────────────
TextStyle syne(double size, {FontWeight weight = FontWeight.normal, Color color = textPrimary, double? letterSpacing}) {
  return GoogleFonts.syne(fontSize: size, fontWeight: weight, color: color, letterSpacing: letterSpacing);
}

TextStyle inter(double size, {FontWeight weight = FontWeight.normal, Color color = textPrimary, double? letterSpacing}) {
  return GoogleFonts.inter(fontSize: size, fontWeight: weight, color: color, letterSpacing: letterSpacing);
}

// ── GLASSMORPHISM WIDGET ─────────────────────────────────────────────────────
Widget _glassCard({required Widget child, Color? accent, double radius = 16, EdgeInsets? padding, double? width, double? height}) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(radius),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: Container(
        width: width,
        height: height,
        padding: padding ?? const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.07),
              Colors.white.withOpacity(0.02),
            ],
          ),
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: accent?.withOpacity(0.25) ?? Colors.white.withOpacity(0.06),
            width: 0.5,
          ),
          boxShadow: accent == null ? [] : [
            BoxShadow(
              color: accent.withOpacity(0.12),
              blurRadius: 20,
              spreadRadius: 2,
            ),
            BoxShadow(
              color: accent.withOpacity(0.05),
              blurRadius: 40,
              spreadRadius: 5,
            ),
          ],
        ),
        child: child,
      ),
    ),
  );
}

// ── MAIN MAP SCREEN ──────────────────────────────────────────────────────────
class CrisisMapScreen extends ConsumerStatefulWidget {
  const CrisisMapScreen({super.key});

  @override
  ConsumerState<CrisisMapScreen> createState() => _CrisisMapScreenState();
}

class _CrisisMapScreenState extends ConsumerState<CrisisMapScreen> {
  GoogleMapController? _mapController;
  late FlutterLocalNotificationsPlugin _notificationsPlugin;
  
  final Set<Circle> _circles = {};
  final Set<Marker> _markers = {};
  final Map<String, Polyline> _polylines = {};
  int _selectedTab = 0;
  String _timeString = '';
  Timer? _timeTimer;

  static const CameraPosition _initialCamera = CameraPosition(
    target: _islamabadCenter,
    zoom: 12.5,
  );

  @override
  void initState() {
    super.initState();
    _initNotifications();
    _startClock();
  }

  @override
  void dispose() {
    _timeTimer?.cancel();
    super.dispose();
  }

  void _startClock() {
    _timeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = DateTime.now();
      setState(() {
        _timeString =
            '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
      });
    });
  }

  void _initNotifications() async {
    _notificationsPlugin = FlutterLocalNotificationsPlugin();
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _notificationsPlugin.initialize(settings: initSettings);
  }

  void _showNotification(String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      'ciro_alerts',
      'CIRO Crisis Alerts',
      channelDescription: 'Alerts for real-time crisis detection and management',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails);
    await _notificationsPlugin.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }

  String _normalize(String str) {
    return str.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  LatLng _getCoords(String location) {
    // 1. Try parsing Lat, Lng coordinates directly (e.g. "33.72, 73.06" or "33.72,73.06")
    final cleanLoc = location.trim();
    final match = RegExp(r'^\s*([+-]?\d+(?:\.\d+)?)\s*,\s*([+-]?\d+(?:\.\d+)?)\s*$').firstMatch(cleanLoc);
    if (match != null) {
      final lat = double.tryParse(match.group(1)!);
      final lng = double.tryParse(match.group(2)!);
      if (lat != null && lng != null) {
        return LatLng(lat, lng);
      }
    }

    // 2. Try normalized static lookup
    final normLocation = _normalize(location);
    for (final entry in _locations.entries) {
      final normKey = _normalize(entry.key);
      if (normLocation.contains(normKey) || normKey.contains(normLocation)) {
        return entry.value;
      }
    }
    // Fallback with slight offset
    final hash = location.hashCode.toDouble() % 100.0;
    return LatLng(
      _islamabadCenter.latitude + (hash / 5000.0) - 0.01,
      _islamabadCenter.longitude + (hash / 5000.0) - 0.01,
    );
  }

  void _animateToLocation(String location) {
    if (_mapController == null) return;
    final coords = _getCoords(location);
    _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: coords,
          zoom: 14.5,
        ),
      ),
    );
  }

  void _updateMapLayers(CrisisAppState appState) {
    _circles.clear();
    _markers.clear();
    _polylines.clear();

    final currentState = appState.currentState;
    if (currentState == null) return;

    // Build Circles
    for (final crisis in currentState.finalState.activeCrises) {
      final coords = _getCoords(crisis.location);
      final radius = (crisis.affectedRadiusKm ?? 1.0) * 1000.0;
      
      Color statusColor = accentCritical;
      if (crisis.status == CrisisStatus.monitoring) statusColor = accentWarning;
      if (crisis.status == CrisisStatus.retracted) statusColor = accentSafe;

      // Base circle
      _circles.add(Circle(
        circleId: CircleId(crisis.id),
        center: coords,
        radius: radius,
        fillColor: statusColor.withOpacity(0.15),
        strokeColor: statusColor,
        strokeWidth: 2,
      ));

      // Inner focus zone circle
      _circles.add(Circle(
        circleId: CircleId('${crisis.id}_inner'),
        center: coords,
        radius: radius * 0.3,
        fillColor: statusColor.withOpacity(0.30),
        strokeColor: statusColor,
        strokeWidth: 1,
      ));
    }

    // Build Markers
    for (final crisis in currentState.finalState.activeCrises) {
      final coords = _getCoords(crisis.location);
      double hue = BitmapDescriptor.hueRed;
      if (crisis.status == CrisisStatus.monitoring) hue = BitmapDescriptor.hueYellow;
      if (crisis.status == CrisisStatus.retracted) hue = BitmapDescriptor.hueGreen;

      _markers.add(Marker(
        markerId: MarkerId(crisis.id),
        position: coords,
        icon: BitmapDescriptor.defaultMarkerWithHue(hue),
        infoWindow: InfoWindow(
          title: crisis.type.toUpperCase(),
          snippet: '${crisis.location} — Severity ${crisis.severity?.toStringAsFixed(1) ?? "?"}/10',
        ),
      ));
    }

    // Polylines if Srinagar Flood active (Phase 2 or later)
    if (appState.currentPhaseNumber >= 2) {
      _polylines['srinagar_closure'] = Polyline(
        polylineId: const PolylineId('srinagar_closure'),
        points: const [
          LatLng(33.6890, 73.0250),
          LatLng(33.6850, 73.0150),
          LatLng(33.6810, 73.0050),
        ],
        color: accentCritical,
        width: 5,
        patterns: [PatternItem.dash(20), PatternItem.gap(10)],
      );

      _polylines['ijp_alternate'] = const Polyline(
        polylineId: PolylineId('ijp_alternate'),
        points: [
          LatLng(33.6600, 73.0050),
          LatLng(33.6620, 73.0150),
          LatLng(33.6640, 73.0250),
        ],
        color: accentSafe,
        width: 4,
      );
    }
  }

  void _showInjectCrisisSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _InjectCrisisSheet(
        onInject: (type, location) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Injected $type at $location — agents responding...', style: inter(13, color: Colors.white, weight: FontWeight.w600)),
              backgroundColor: accentCritical,
              behavior: SnackBarBehavior.floating,
            ),
          );
          ref.read(crisisProvider.notifier).injectCrisis(type, location);
        },
      ),
    );
  }

  void _showFieldReportSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _FieldReportSheet(
        onConfirm: () {
          Navigator.pop(context);
          ref.read(crisisProvider.notifier).submitFieldReport(true);
        },
        onRetract: () {
          Navigator.pop(context);
          ref.read(crisisProvider.notifier).submitFieldReport(false);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(crisisProvider);
    final isRunning = appState.phase != SimulationPhase.idle && appState.phase != SimulationPhase.finished;
    
    ref.listen<CrisisAppState>(crisisProvider, (previous, next) {
      if (next.currentState != null) {
        _updateMapLayers(next);
        
        final currentCrises = next.currentState!.finalState.activeCrises;
        final previousCrises = previous?.currentState?.finalState.activeCrises ?? [];
        
        if (currentCrises.isNotEmpty) {
          final newCrisis = currentCrises.firstWhere(
            (c) => !previousCrises.any((pc) => pc.id == c.id),
            orElse: () => currentCrises.last,
          );
          
          if (previousCrises.isEmpty || currentCrises.length > previousCrises.length) {
            _animateToLocation(newCrisis.location);
          }
        }

        if (currentCrises.length > previousCrises.length) {
          final newCrisis = currentCrises.firstWhere(
            (c) => !previousCrises.any((pc) => pc.id == c.id),
            orElse: () => currentCrises.last,
          );
          _showNotification(
            '🚨 NEW CRISIS: ${newCrisis.type.toUpperCase()}',
            'Location: ${newCrisis.location} | Severity: ${newCrisis.severity?.toStringAsFixed(1) ?? "N/A"}/10',
          );
        }
      }
    });

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Google Map Layer
          GoogleMap(
            initialCameraPosition: _initialCamera,
            circles: _circles,
            markers: _markers,
            polylines: Set<Polyline>.of(_polylines.values),
            onMapCreated: (controller) {
              _mapController = controller;
              controller.setMapStyle(_darkMapStyle);
            },
          ),

          // Custom Top Header
          Positioned(
            top: 0, left: 0, right: 0,
            child: _TopBar(timeString: _timeString, isRunning: isRunning),
          ),

          // Degraded Mode Banner
          Positioned(
            top: MediaQuery.of(context).padding.top + 80, left: 0, right: 0,
            child: _DegradedBanner(visible: appState.degradedMode),
          ),

          // Active Phase Indicator
          if (isRunning)
            Positioned(
              top: MediaQuery.of(context).padding.top + 96,
              right: 16,
              child: _PhaseIndicator(
                phaseIndex: appState.currentPhaseNumber - 1,
                phaseLabel: appState.currentPhaseLabel,
                isLoading: appState.isLoading,
              ),
            ),

          // Error Overlay
          if (appState.errorMessage != null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 150,
              left: 16, right: 16,
              child: _ErrorOverlay(
                errorMessage: appState.errorMessage!,
                onRetry: () => ref.read(crisisProvider.notifier).startSimulation(),
              ),
            ),

          // Floating Action Buttons (FAB Column)
          Positioned(
            bottom: MediaQuery.of(context).size.height * 0.38 + 20,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (appState.phase != SimulationPhase.idle) ...[
                  FloatingActionButton.small(
                    onPressed: _showInjectCrisisSheet,
                    backgroundColor: surfaceLight,
                    child: const Icon(Icons.add_alert_rounded, color: accentInfo),
                  ).animate().scale(delay: 100.ms),
                  const SizedBox(height: 8),
                  FloatingActionButton.small(
                    onPressed: _showFieldReportSheet,
                    backgroundColor: surfaceLight,
                    child: const Icon(Icons.assignment_ind_rounded, color: accentSafe),
                  ).animate().scale(delay: 200.ms),
                  const SizedBox(height: 8),
                ],
                FloatingActionButton.extended(
                  onPressed: () {
                    HapticFeedback.heavyImpact();
                    if (appState.phase == SimulationPhase.finished) {
                      ref.read(crisisProvider.notifier).resetSimulation();
                    } else {
                      ref.read(crisisProvider.notifier).startSimulation();
                    }
                  },
                  backgroundColor: appState.phase == SimulationPhase.finished ? accentPurple : accentCritical,
                  icon: Icon(
                    appState.phase == SimulationPhase.finished
                        ? Icons.replay_rounded
                        : (appState.isLoading ? Icons.hourglass_empty_rounded : Icons.play_arrow_rounded),
                    color: Colors.white,
                  ),
                  label: Text(
                    appState.phase == SimulationPhase.finished
                        ? 'RESET'
                        : (appState.isLoading ? 'PROCESSING...' : 'SIMULATE'),
                    style: syne(12, weight: FontWeight.w700, letterSpacing: 1),
                  ),
                ).animate().scale(),
              ],
            ),
          ),

          // Draggable Bottom Crisis Command Panel
          _BottomCommandPanel(
            selectedTab: _selectedTab,
            onTabChanged: (index) => setState(() => _selectedTab = index),
            onTapCrisis: _animateToLocation,
          ),
        ],
      ),
    );
  }
}

// ── CUSTOM TOP BAR ───────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final String timeString;
  final bool isRunning;
  const _TopBar({required this.timeString, required this.isRunning});

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          height: 80 + topPadding,
          padding: EdgeInsets.only(top: topPadding, left: 20, right: 20),
          decoration: BoxDecoration(
            color: bgPrimary.withOpacity(0.85),
            border: const Border(bottom: BorderSide(color: Colors.white10, width: 0.5)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('CIRO COMMAND CENTER', style: syne(14, weight: FontWeight.w800, color: accentSafe, letterSpacing: 0.5), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text('AUTONOMOUS CRISIS SIMULATION', style: inter(8, weight: FontWeight.w500, color: textSecondary, letterSpacing: 1), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(timeString, style: syne(14, weight: FontWeight.w700, color: accentInfo)),
              if (isRunning) ...[
                const SizedBox(width: 12),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6, height: 6,
                      decoration: const BoxDecoration(color: accentCritical, shape: BoxShape.circle),
                    ).animate(onPlay: (c) => c.repeat(reverse: true)).fadeOut(duration: 800.ms),
                    const SizedBox(width: 4),
                    Text('LIVE ENGINE', style: inter(9, weight: FontWeight.w700, color: accentCritical)),
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

// ── DEGRADED MODE BANNER ──────────────────────────────────────────────────────
class _DegradedBanner extends StatelessWidget {
  final bool visible;
  const _DegradedBanner({required this.visible});

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      offset: visible ? Offset.zero : const Offset(0, -1.5),
      duration: 400.ms,
      curve: Curves.easeInOut,
      child: AnimatedOpacity(
        opacity: visible ? 1.0 : 0.0,
        duration: 400.ms,
        child: Container(
          color: accentWarning,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Row(
            children: [
              const Icon(Icons.wifi_off_rounded, color: bgPrimary, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'DEGRADED MODE — Weather API offline. Using cached rainfall values (Telemetry decay -0.15).',
                  style: inter(11, color: bgPrimary, weight: FontWeight.w700),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: bgPrimary, borderRadius: BorderRadius.circular(4)),
                child: Text('CACHED', style: syne(9, weight: FontWeight.w800, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── PHASE INDICATOR ──────────────────────────────────────────────────────────
class _PhaseIndicator extends ConsumerWidget {
  final int phaseIndex;
  final String phaseLabel;
  final bool isLoading;

  const _PhaseIndicator({
    required this.phaseIndex,
    required this.phaseLabel,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countdownAsync = ref.watch(countdownProvider);
    final seconds = countdownAsync.value ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (seconds > 0) ...[
          _glassCard(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            accent: accentWarning,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.timer_outlined, color: accentWarning, size: 14),
                const SizedBox(width: 6),
                Text('Next phase in: ${seconds}s', style: syne(10, weight: FontWeight.w700, color: accentWarning)),
              ],
            ),
          ).animate().fadeIn().scale(),
          const SizedBox(height: 8),
        ],
        _glassCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('CURRENT PHASE', style: syne(8, weight: FontWeight.w700, color: textSecondary, letterSpacing: 1.5)),
                  Text(phaseLabel, style: inter(10, weight: FontWeight.w600, color: accentInfo)),
                ],
              ),
              const SizedBox(width: 12),
              Row(
                children: List.generate(4, (index) {
                  final active = index == phaseIndex;
                  final completed = index < phaseIndex;
                  return Container(
                    width: 8, height: 8,
                    margin: const EdgeInsets.only(left: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: completed
                          ? accentSafe
                          : (active ? (isLoading ? accentCritical : accentInfo) : Colors.white24),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── ERROR OVERLAY ────────────────────────────────────────────────────────────
class _ErrorOverlay extends StatelessWidget {
  final String errorMessage;
  final VoidCallback onRetry;
  const _ErrorOverlay({required this.errorMessage, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return _glassCard(
      accent: accentCritical,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: accentCritical, size: 24),
              const SizedBox(width: 12),
              Text('SIMULATION FAULT ENCOUNTERED', style: syne(14, weight: FontWeight.w800, color: accentCritical)),
            ],
          ),
          const SizedBox(height: 8),
          Text(errorMessage, style: inter(12, color: textPrimary)),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(backgroundColor: accentCritical),
            child: Text('RETRY PIPELINE', style: syne(12, weight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ── BOTTOM DRAGGABLE COMMAND PANEL ───────────────────────────────────────────
class _BottomCommandPanel extends ConsumerWidget {
  final int selectedTab;
  final ValueChanged<int> onTabChanged;
  final ValueChanged<String> onTapCrisis;

  const _BottomCommandPanel({
    required this.selectedTab,
    required this.onTabChanged,
    required this.onTapCrisis,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(crisisProvider);
    
    return DraggableScrollableSheet(
      initialChildSize: 0.38,
      minChildSize: 0.12,
      maxChildSize: 0.95,
      builder: (context, controller) {
        return Container(
          decoration: BoxDecoration(
            color: bgSecondary.withOpacity(0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: Colors.white10, width: 0.5),
          ),
          child: Column(
            children: [
              // Top drag bar handle
              Container(
                width: 40, height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
              ),

              // Tab Headers
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildTabHeader(0, 'SIGNALS', Icons.sensors_rounded),
                    const SizedBox(width: 8),
                    _buildTabHeader(1, 'CRISES', Icons.warning_amber_rounded),
                    const SizedBox(width: 8),
                    _buildTabHeader(2, 'ACTIONS', Icons.flash_on_rounded),
                    const SizedBox(width: 8),
                    _buildTabHeader(3, 'TRACES', Icons.psychology_rounded),
                  ],
                ),
              ),

              const Divider(color: Colors.white10, height: 16),

              // Dynamic Tab Content
              Expanded(
                child: appState.isLoading
                    ? _buildShimmerLoading()
                    : _buildTabContent(appState, controller),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTabHeader(int index, String label, IconData icon) {
    final active = selectedTab == index;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTabChanged(index);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: active ? surfaceLight : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: active ? accentInfo : textSecondary),
            const SizedBox(width: 6),
            Text(label, style: syne(10, weight: FontWeight.w700, color: active ? textPrimary : textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: surfaceLight,
      highlightColor: surfaceLight.withOpacity(0.4),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 3,
        itemBuilder: (context, index) => Container(
          height: 70,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildTabContent(CrisisAppState appState, ScrollController controller) {
    switch (selectedTab) {
      case 0:
        return _SignalsPanelTab(appState: appState, controller: controller, onTapLocation: onTapCrisis);
      case 1:
        return _CrisesPanelTab(appState: appState, controller: controller, onTapLocation: onTapCrisis);
      case 2:
        return _ActionsPanelTab(appState: appState, controller: controller);
      case 3:
        return _TracesPanelTab(appState: appState, controller: controller);
      default:
        return const SizedBox();
    }
  }
}

// ── SIGNALS TAB CONTENT ──────────────────────────────────────────────────────
class _SignalsPanelTab extends StatelessWidget {
  final CrisisAppState appState;
  final ScrollController controller;
  final ValueChanged<String> onTapLocation;

  const _SignalsPanelTab({
    required this.appState,
    required this.controller,
    required this.onTapLocation,
  });

  @override
  Widget build(BuildContext context) {
    final feed = appState.signalFeed;
    if (feed.isEmpty) {
      return Center(child: Text('NO SIGNALS INGESTED YET', style: syne(12, color: textSecondary)));
    }
    return ListView.builder(
      controller: controller,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: feed.length,
      itemBuilder: (context, index) {
        final signal = feed[index];
        final source = signal['source'] ?? 'sensor';
        
        Color sourceColor = accentPurple;
        IconData icon = Icons.sensors_rounded;

        if (source == 'anonymous_social' || source == 'social_post') {
          sourceColor = accentCritical;
          icon = Icons.people_alt_rounded;
        } else if (source == 'weather_api') {
          sourceColor = accentInfo;
          icon = Icons.cloud_rounded;
        } else if (source == 'traffic_api') {
          sourceColor = accentWarning;
          icon = Icons.traffic_rounded;
        } else if (source == 'field_report') {
          sourceColor = accentSafe;
          icon = Icons.assignment_ind_rounded;
        }

        final double credibility = (signal['base_credibility'] as num?)?.toDouble() ?? 0.5;

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              final locationHint = signal['location_hint'] ?? 'Islamabad';
              onTapLocation(locationHint);
            },
            child: _glassCard(
              padding: const EdgeInsets.all(12),
              radius: 12,
              child: Row(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(color: sourceColor.withOpacity(0.1), shape: BoxShape.circle),
                    child: Icon(icon, color: sourceColor, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(source.toUpperCase().replaceAll('_', ' '), style: syne(8, weight: FontWeight.w700, color: sourceColor, letterSpacing: 1)),
                            const Spacer(),
                            Text(signal['timestamp'] ?? '', style: inter(9, color: textSecondary)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(signal['text'] ?? '', style: inter(12, color: textPrimary)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: sourceColor.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
                    child: Text(credibility.toStringAsFixed(2), style: syne(10, weight: FontWeight.w800, color: sourceColor)),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── CRISES TAB CONTENT ───────────────────────────────────────────────────────
class _CrisesPanelTab extends StatelessWidget {
  final CrisisAppState appState;
  final ScrollController controller;
  final ValueChanged<String> onTapLocation;

  const _CrisesPanelTab({
    required this.appState,
    required this.controller,
    required this.onTapLocation,
  });

  @override
  Widget build(BuildContext context) {
    final state = appState.currentState;
    if (state == null || state.finalState.activeCrises.isEmpty) {
      return Center(child: Text('COMMAND CENTER IDLE — NO CRISES REGISTERED', style: syne(12, color: textSecondary)));
    }

    final activeCrises = state.finalState.activeCrises;

    return ListView.builder(
      controller: controller,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: activeCrises.length,
      itemBuilder: (context, index) {
        final crisis = activeCrises[index];
        final severity = crisis.severity ?? 5.0;

        Color severityColor = accentSafe;
        if (severity >= 7) {
          severityColor = accentCritical;
        } else if (severity >= 4) {
          severityColor = accentWarning;
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              onTapLocation(crisis.location);
            },
            child: _glassCard(
              accent: severityColor,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row
                  Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(crisis.type.toUpperCase(), style: syne(14, weight: FontWeight.w800, color: textPrimary)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: severityColor.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                        child: Text('SEVERITY: ${severity.toStringAsFixed(1)}', style: syne(10, weight: FontWeight.w800, color: severityColor)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Location: ${crisis.location}', style: inter(12, color: textSecondary)),
                  
                  // Confidence gauge
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text('Confidence', style: syne(9, color: textSecondary)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: crisis.confidence,
                            backgroundColor: Colors.white10,
                            valueColor: AlwaysStoppedAnimation<Color>(accentInfo),
                            minHeight: 4,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('${(crisis.confidence * 100).toInt()}%', style: syne(9, color: textPrimary)),
                    ],
                  ),

                  // Cascade effects
                  if (crisis.cascadeEffects.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6, runSpacing: 6,
                      children: crisis.cascadeEffects.map((e) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(4)),
                        child: Text(e, style: inter(9, color: textPrimary)),
                      )).toList(),
                    ),
                  ],

                  // Action Plan / Stakeholder communication triggers
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () => _showMessagesDialog(context, state, crisis.id),
                    style: ElevatedButton.styleFrom(backgroundColor: surfaceLight),
                    icon: const Icon(Icons.forum_rounded, size: 14, color: accentInfo),
                    label: Text('STAKEHOLDER COMMUNIQUE', style: syne(10, weight: FontWeight.w700, color: textPrimary)),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showMessagesDialog(BuildContext context, CrisisState state, String crisisId) {
    // Find matching allocation and stakeholder messages
    final allocation = state.agentTraces.agent3.allocations.firstWhere(
      (a) => a.crisisId == crisisId,
      orElse: () => state.agentTraces.agent3.allocations.first,
    );

    final msgs = allocation.stakeholderMessages;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: _glassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('STAKEHOLDER BROADCASTS', style: syne(16, weight: FontWeight.w800, color: accentInfo)),
              const SizedBox(height: 4),
              Text('Autonomous agency transmissions generated for dispatch.', style: inter(10, color: textSecondary)),
              const SizedBox(height: 16),
              SizedBox(
                height: 350,
                child: ListView(
                  children: [
                    _buildMessageItem('PUBLIC (ENGLISH)', msgs.publicEnglish, accentCritical),
                    _buildMessageItem('PUBLIC (URDU)', msgs.publicUrdu, accentSafe),
                    _buildMessageItem('PIMS HOSPITAL', msgs.pimsHospital, accentInfo),
                    _buildMessageItem('TRAFFIC AUTHORITY', msgs.trafficAuthority, accentWarning),
                    _buildMessageItem('IESCO UTILITY', msgs.iescoutility, accentPurple),
                    _buildMessageItem('MEDIA OUTLETS', msgs.mediaCommand, textSecondary),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('ACKNOWLEDGE DISPATCH', style: syne(12, weight: FontWeight.w700, color: accentSafe)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageItem(String label, String message, Color tintColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: syne(9, weight: FontWeight.w800, color: tintColor, letterSpacing: 1)),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
            child: Text(message.isNotEmpty ? message : 'N/A', style: inter(11, color: textPrimary)),
          ),
        ],
      ),
    );
  }
}

// ── ACTIONS & RESOURCES TAB CONTENT ──────────────────────────────────────────
class _ActionsPanelTab extends StatelessWidget {
  final CrisisAppState appState;
  final ScrollController controller;

  const _ActionsPanelTab({required this.appState, required this.controller});

  @override
  Widget build(BuildContext context) {
    final state = appState.currentState;
    
    return ListView(
      controller: controller,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        // Resource Pool Status
        Text('EMERGENCY RESOURCE POOL', style: syne(11, weight: FontWeight.w700, color: textSecondary, letterSpacing: 1.5)),
        const SizedBox(height: 8),
        if (state != null) ...[
          _buildResourceGauges(state.finalState.resourcePoolRemaining),
        ] else ...[
          _buildResourceGauges(const ResourceBundle(ambulances: 4, rescueTeams: 3, policeUnits: 5, medicalVans: 2)),
        ],

        // Trade-off rationales if any
        if (appState.tradeoffRationale != null) ...[
          const SizedBox(height: 16),
          _glassCard(
            accent: accentWarning,
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.swap_horizontal_circle_rounded, color: accentWarning, size: 18),
                    const SizedBox(width: 8),
                    Text('RESOURCE TRADE-OFF RATIONALE', style: syne(11, weight: FontWeight.w800, color: accentWarning)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(appState.tradeoffRationale!, style: inter(11, color: textPrimary)),
              ],
            ),
          ),
        ],

        // Historic actions log
        const SizedBox(height: 16),
        Text('AGENTIC DISPATCH ACTIONS LOG', style: syne(11, weight: FontWeight.w700, color: textSecondary, letterSpacing: 1.5)),
        const SizedBox(height: 8),
        _buildHistoricActionsList(),
      ],
    );
  }

  Widget _buildResourceGauges(ResourceBundle current) {
    const total = ResourceBundle(ambulances: 4, rescueTeams: 3, policeUnits: 5, medicalVans: 2);
    return Row(
      children: [
        Expanded(child: _buildResourceCard('AMBULANCES', current.ambulances, total.ambulances, Icons.local_hospital_rounded)),
        const SizedBox(width: 8),
        Expanded(child: _buildResourceCard('RESCUE TEAMS', current.rescueTeams, total.rescueTeams, Icons.people_alt_rounded)),
        const SizedBox(width: 8),
        Expanded(child: _buildResourceCard('POLICE UNITS', current.policeUnits, total.policeUnits, Icons.local_police_rounded)),
        const SizedBox(width: 8),
        Expanded(child: _buildResourceCard('MEDICAL VANS', current.medicalVans, total.medicalVans, Icons.airport_shuttle_rounded)),
      ],
    );
  }

  Widget _buildResourceCard(String label, int current, int max, IconData icon) {
    final double pct = max > 0 ? (current / max).clamp(0.0, 1.0) : 0.0;
    Color healthColor = accentSafe;
    if (pct < 0.3) {
      healthColor = accentCritical;
    } else if (pct < 0.6) {
      healthColor = accentWarning;
    }

    return _glassCard(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      radius: 10,
      child: Column(
        children: [
          Icon(icon, color: accentPurple, size: 16),
          const SizedBox(height: 4),
          Text(label, style: syne(7, weight: FontWeight.w700, color: textSecondary)),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('$current', style: syne(14, weight: FontWeight.w800, color: healthColor)),
              Text('/$max', style: inter(10, color: textSecondary)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(1.5),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: Colors.white.withOpacity(0.05),
              valueColor: AlwaysStoppedAnimation<Color>(healthColor),
              minHeight: 3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoricActionsList() {
    final history = appState.history;
    if (history.isEmpty) {
      return Center(child: Text('NO ACTIONS GENERATED YET', style: syne(10, color: textSecondary)));
    }

    final List<Map<String, dynamic>> allActions = [];
    for (final state in history) {
      for (final allocation in state.agentTraces.agent3.allocations) {
        for (final action in allocation.actions) {
          allActions.add({
            'time': state.simulationTime,
            'desc': action.description,
            'state': action.stateChange,
          });
        }
      }
    }

    return Column(
      children: allActions.map((action) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: _glassCard(
            padding: const EdgeInsets.all(10),
            radius: 8,
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline_rounded, color: accentSafe, size: 16),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(action['desc'] ?? '', style: inter(12, color: textPrimary)),
                      Text('System state change: ${action['state'] ?? ""}', style: inter(9, color: textSecondary)),
                    ],
                  ),
                ),
                Text(action['time'] ?? '', style: inter(9, color: textSecondary)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── AGENT TRACES TAB CONTENT ─────────────────────────────────────────────────
class _TracesPanelTab extends StatelessWidget {
  final CrisisAppState appState;
  final ScrollController controller;

  const _TracesPanelTab({required this.appState, required this.controller});

  @override
  Widget build(BuildContext context) {
    final state = appState.currentState;
    if (state == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.psychology_rounded, size: 48, color: Colors.white24),
            const SizedBox(height: 12),
            Text('TAP SIMULATE TO TRIGGER ORCHESTRATION', style: syne(11, color: textSecondary)),
          ],
        ),
      );
    }

    return ListView(
      controller: controller,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        _buildAgentTraceBox('AGENT 1: SIGNAL FUSION ENGINE', state.agentTraces.agent1.steps, accentInfo),
        const SizedBox(height: 12),
        _buildAgentTraceBox('AGENT 2: CRISIS DETECTION ENGINE', state.agentTraces.agent2.steps, accentWarning),
        const SizedBox(height: 12),
        _buildAgentTraceBox('AGENT 3: ALLOCATION & DECISION GATEWAY', state.agentTraces.agent3.steps, accentPurple),
      ],
    );
  }

  Widget _buildAgentTraceBox(String agentLabel, List<String> steps, Color tintColor) {
    return _glassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 4, height: 12, decoration: BoxDecoration(color: tintColor, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 8),
              Expanded(
                child: Text(agentLabel, style: syne(10, weight: FontWeight.w800, color: tintColor, letterSpacing: 1)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...steps.map((s) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• ', style: inter(12, color: tintColor)),
                Expanded(child: Text(s, style: inter(12, color: textPrimary))),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

// ── DIALOG & BOTTOM SHEETS ───────────────────────────────────────────────────
class _InjectCrisisSheet extends StatefulWidget {
  final Function(String type, String location) onInject;
  const _InjectCrisisSheet({required this.onInject});

  @override
  State<_InjectCrisisSheet> createState() => _InjectCrisisSheetState();
}

class _InjectCrisisSheetState extends State<_InjectCrisisSheet> {
  String _selectedType = 'FLOOD';
  String _selectedLocation = 'G-10';
  bool _isCustom = false;
  final _customLocationController = TextEditingController();

  @override
  void dispose() {
    _customLocationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: bgSecondary.withOpacity(0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('INJECT SYNTHETIC CRISIS SIGNAL', style: syne(16, weight: FontWeight.w800, color: accentInfo)),
          const SizedBox(height: 16),
          
          DropdownButtonFormField<String>(
            value: _selectedType,
            decoration: const InputDecoration(labelText: 'CRISIS TYPE'),
            items: const [
              DropdownMenuItem(value: 'FLOOD', child: Text('FLOOD')),
              DropdownMenuItem(value: 'ACCIDENT', child: Text('ACCIDENT')),
              DropdownMenuItem(value: 'HEATWAVE', child: Text('HEATWAVE')),
              DropdownMenuItem(value: 'FIRE', child: Text('FIRE')),
              DropdownMenuItem(value: 'POWER_OUTAGE', child: Text('POWER_OUTAGE')),
            ],
            onChanged: (v) => setState(() => _selectedType = v!),
          ),
          const SizedBox(height: 12),
          
          DropdownButtonFormField<String>(
            value: _selectedLocation,
            decoration: const InputDecoration(labelText: 'LOCATION'),
            items: const [
              DropdownMenuItem(value: 'G-10', child: Text('G-10 (Sector Centroid)')),
              DropdownMenuItem(value: 'G-13', child: Text('G-13 (Sector Centroid)')),
              DropdownMenuItem(value: 'Murree Road', child: Text('Murree Road (Faizabad)')),
              DropdownMenuItem(value: 'F-7', child: Text('F-7 (Sector Centroid)')),
              DropdownMenuItem(value: 'Dhok Hassu', child: Text('Dhok Hassu (Rawalpindi)')),
              DropdownMenuItem(value: 'Blue Area', child: Text('Blue Area (Business District)')),
              DropdownMenuItem(value: 'Centaurus Mall', child: Text('Centaurus Mall')),
              DropdownMenuItem(value: 'Zero Point', child: Text('Zero Point Interchange')),
              DropdownMenuItem(value: 'CUSTOM', child: Text('Custom Sector / Exact Lat, Lng...')),
            ],
            onChanged: (v) {
              setState(() {
                _selectedLocation = v!;
                _isCustom = v == 'CUSTOM';
              });
            },
          ),

          if (_isCustom) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _customLocationController,
              style: inter(14, color: textPrimary),
              decoration: InputDecoration(
                labelText: 'CUSTOM LOCATION OR COORDINATES',
                hintText: 'e.g. F-6, E-11, or exact 33.72, 73.06',
                hintStyle: inter(12, color: textSecondary),
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.location_on_rounded, color: accentInfo),
                filled: true,
                fillColor: Colors.white.withOpacity(0.02),
              ),
            ),
          ],
          
          const SizedBox(height: 20),
          
          ElevatedButton(
            onPressed: () {
              final loc = _isCustom ? _customLocationController.text.trim() : _selectedLocation;
              if (loc.isEmpty) return;
              Navigator.pop(context);
              widget.onInject(_selectedType, loc);
            },
            style: ElevatedButton.styleFrom(backgroundColor: accentCritical, padding: const EdgeInsets.symmetric(vertical: 14)),
            child: Text('TRANSMIT SIGNAL TELEMETRY', style: syne(12, weight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _FieldReportSheet extends StatelessWidget {
  final VoidCallback onConfirm;
  final VoidCallback onRetract;

  const _FieldReportSheet({required this.onConfirm, required this.onRetract});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: bgSecondary.withOpacity(0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('SITE VERIFICATION FEEDBACK', style: syne(16, weight: FontWeight.w800, color: accentSafe)),
          const SizedBox(height: 8),
          Text('Acknowledge verification report from on-site emergency units.', style: inter(11, color: textSecondary)),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: onConfirm,
                  style: ElevatedButton.styleFrom(backgroundColor: accentSafe, padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: Text('VERIFY CRISIS', style: syne(12, weight: FontWeight.w800, color: bgPrimary)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: onRetract,
                  style: ElevatedButton.styleFrom(backgroundColor: accentCritical, padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: Text('RETRACT FALSE ALARM', style: syne(12, weight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
