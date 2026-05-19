import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/crisis_provider.dart';
import '../ui/design_system.dart';

class TopBar extends StatefulWidget {
  final bool isRunning;
  const TopBar({super.key, required this.isRunning});

  @override
  State<TopBar> createState() => _TopBarState();
}

class _TopBarState extends State<TopBar> {
  late String _time;

  @override
  void initState() {
    super.initState();
    _tick();
  }

  void _tick() {
    if (!mounted) return;
    final now = DateTime.now();
    setState(() {
      _time =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    });
    Future.delayed(const Duration(seconds: 1), _tick);
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          height: 80 + top,
          padding: EdgeInsets.only(top: top, left: 20, right: 20),
          decoration: BoxDecoration(
            color: bgPrimary.withOpacity(0.85),
            border: Border(
              bottom: BorderSide(color: accentInfo.withOpacity(0.15), width: 1),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left — brand
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Nigehbaan AI (نگہبان)', style: syne(22, weight: FontWeight.w800, color: accentSafe)),
                  Text('ISLAMABAD INCIDENT COMMAND',
                      style: inter(10, weight: FontWeight.w500, color: textSecondary, letterSpacing: 2.5)),
                ],
              ),
              // Center — clock
              Expanded(
                child: Center(
                  child: Text(_time,
                      style: syne(18, weight: FontWeight.w600, color: accentInfo)),
                ),
              ),
              // Right — LIVE indicator + Countdown
              if (widget.isRunning)
                Consumer(
                  builder: (context, ref, child) {
                    final countdownAsync = ref.watch(countdownProvider);
                    final seconds = countdownAsync.value ?? 0;
                    return Row(
                      children: [
                        if (seconds > 0) ...[
                          Text('NEXT IN ${seconds}S', style: inter(10, color: textSecondary, weight: FontWeight.w600, letterSpacing: 1.5)),
                          const SizedBox(width: 12),
                        ],
                        _BlinkDot(),
                        const SizedBox(width: 6),
                        Text('LIVE', style: inter(11, weight: FontWeight.w600, color: accentCritical)),
                      ],
                    );
                  }
                ).animate().fadeIn(duration: 400.ms),
            ],
          ),
        ),
      ),
    );
  }
}

class _BlinkDot extends StatefulWidget {
  @override
  State<_BlinkDot> createState() => _BlinkDotState();
}

class _BlinkDotState extends State<_BlinkDot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: _ctrl,
        child: Container(
          width: 8, height: 8,
          decoration: BoxDecoration(
            color: accentCritical,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: accentCritical.withOpacity(0.7), blurRadius: 6)],
          ),
        ),
      );
}
