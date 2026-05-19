# CIRO — Antigravity Agent Traces

This document contains the internal reasoning steps for the CIRO multi-agent pipeline. Use this for your "Antigravity Usage" demo video.

## Agent 1: Signal Fusion
**Input**: Raw signals (Roman Urdu social posts, weather API, traffic telemetry).
**Logic**:
- **Freshness Multiplier**: S1(10:42) age=3min → 1.0.
- **Mention Velocity**: 3 social posts in 5 mins → boost +0.20.
- **Formula**: `(base_credibility + boost) × freshness`.
- **Corroboration**: 3 distinct source types (social, weather, traffic) → ×1.35 boost.
- **Outcome**: Fused G-10 signal with **0.90 credibility**.

## Agent 2: Crisis Detection & Analysis
**Input**: Fused signals from Agent 1.
**Logic**:
- **Classification**: G-10 credibility 0.90 ≥ 0.60 → **CRISIS CONFIRMED**.
- **Severity**: Base 7 (flood) + 1 (G-10 density) + 0 (high confidence) = **8/10**.
- **Cascades**: Predicts hospital surge, electrical hazards, and traffic displacement.
- **Radius**: Calculated affected zone of **2.5km**.

## Agent 3: Resource Allocation & Action
**Input**: Crises array from Agent 2.
**Logic**:
- **Priority Scoring**: `severity × density / (1 + distance)`. G-10 Score: **64.0**.
- **Greedy Allocation**: Assigned 2 ambulances, 2 rescue teams, 3 police units.
- **Action Generation**:
  - Dispatching ambulances via Kashmir Highway.
  - Setting up field triage at G-10 entry.
  - Rerouting traffic to IJP Road.
  - Triggering PIMS trauma bed reservation.

## Scenario: Field Report (False Alarm Retraction)
- **New Signal**: Field Report (S8) arrives at 10:58. Credibility 0.85.
- **Conflict**: S8 reports "burst water main, not surface flooding".
- **Agent 1 Override**: Field report credibility (0.85) > fused social (0.55).
- **Agent 2 Reclassification**: Event reclassified to **Infrastructure Failure**. Severity drops to 5.
- **Agent 3 Retraction**: Rescue teams recalled. Public flood alert retracted. IESCO crew dispatched for pipe repair.

## Scenario: API Failure (Degraded Mode)
- **Trigger**: Weather API (S4) becomes unavailable.
- **Fallback**: System switches to **cached rainfall data** (68mm/hr).
- **Agent 1 Adjustment**: Credibility degradation factor applied to cached data.
- **Status**: **Degraded Mode Active**. Operators notified of stale weather telemetry. Confidence adjusted from 0.90 to 0.77.
