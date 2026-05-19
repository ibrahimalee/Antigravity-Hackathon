# SafeBite — Full Implementation Plan

Make the SafeBite Flutter + FastAPI app ready to run on a device with **multi-million-dollar UI/UX quality**. The existing codebase has backend + database + partial Flutter code. Missing: entry point, routing, theming, and several core screens.

## 🎨 Premium UI/UX Design Philosophy

> [!IMPORTANT]
> Every screen must look like it was designed by a $500/hr design agency. No generic Material defaults. No flat, boring layouts. The app must feel alive, luxurious, and medically trustworthy.

**Design pillars applied to EVERY screen:**

| Technique | Implementation |
|---|---|
| **Glassmorphism** | Frosted glass cards with `BackdropFilter` + `ImageFilter.blur`, semi-transparent borders, depth layering |
| **Spring physics animations** | All transitions use `Curves.elasticOut` / spring simulations — nothing feels robotic |
| **Custom gradient system** | Deep dark backgrounds (`#0A0A1A` → `#1A1A2E`), never plain `Colors.black`. Radial glows behind key elements |
| **Animated reticle (scanner)** | Already implemented — pulsing corner brackets + sweeping scan line with glow shadows |
| **Nutrition rings** | Custom `CustomPainter` arc rings with gradient strokes, animated fill on load, inner glow |
| **Pet avatar** | Animated emoji-based pet with bounce/wiggle on state change, health bar with gradient fill + shimmer |
| **Micro-interactions** | Button press scales (0.95x), cards lift with shadow on hover/tap, staggered list entry animations |
| **Typography** | Google Fonts `Inter` — tight letter spacing for headers, generous line height for body |
| **Haptic feedback** | Heavy impact on danger, medium on caution, light on safe — already in result sheet |
| **Particle effects** | Subtle floating particles on dashboard background using `CustomPainter` |

---

## Proposed Changes

### Flutter Project Scaffolding

#### [NEW] Flutter project initialization
- Run `flutter create` to generate Android/iOS/web structure, preserve existing `lib/` and `pubspec.yaml`

---

### Core Architecture Files

#### [NEW] [app_config.dart](file:///d:/Safebite/frontend/lib/core/app_config.dart)
- Supabase URL + anon key placeholders, API base URL

#### [NEW] [theme.dart](file:///d:/Safebite/frontend/lib/core/theme.dart)
- **Premium dark theme**: deep navy backgrounds, not plain black
- Brand color system: Danger `#E63946`, Safe `#2EC4B6`, Caution `#FF9F1C`
- Google Fonts Inter typography with custom weight scale
- Glassmorphic card/dialog/bottomSheet themes with blur + transparency
- Custom ElevatedButton theme with gradient backgrounds + press animations

#### [NEW] [router.dart](file:///d:/Safebite/frontend/lib/core/router.dart)
- GoRouter: `/auth`, `/dashboard`, `/scanner`, `/diary`, `/emergency-card`
- Auth redirect guard, custom page transitions (fade + slide)

#### [NEW] [main.dart](file:///d:/Safebite/frontend/lib/main.dart)
- Supabase + Hive init, ProviderScope, MaterialApp.router

---

### Missing Screens (All with Premium UI)

#### [NEW] [auth_screen.dart](file:///d:/Safebite/frontend/lib/screens/auth_screen.dart)
- Animated gradient background with floating particles
- Glassmorphic login card with glow border
- Animated logo + tagline entrance, smooth form field focus transitions

#### [NEW] [dashboard_screen.dart](file:///d:/Safebite/frontend/lib/screens/dashboard_screen.dart)
- **Hero section**: Pet avatar with animated bounce, health gradient bar with shimmer, mood-based background glow
- **Nutrition rings**: 7 custom-painted arc progress rings with gradient strokes + percentage labels, staggered entrance animation
- **Recent scans**: Glassmorphic card list with verdict color accent, staggered slide-in
- **Bottom nav**: Frosted glass navigation bar with glow indicator on active tab
- **Floating particles**: Subtle background particle system

#### [NEW] [symptom_diary_screen.dart](file:///d:/Safebite/frontend/lib/screens/symptom_diary_screen.dart)
- Animated severity slider with gradient track (green → red)
- Symptom selection as animated filter chips with pulse on select
- Timeline list of past entries with color-coded severity badges

#### [NEW] [emergency_card_screen.dart](file:///d:/Safebite/frontend/lib/screens/emergency_card_screen.dart)
- Red gradient card with pulsing border animation (signals urgency)
- Language switcher (EN/DE/UR) with animated transition
- Large, scannable text listing all 15 restricted ingredients
- "Show to chef" visual cue with phone-rotation suggestion

---

### Code Fixes in Existing Files

#### [MODIFY] [result_bottom_sheet.dart](file:///d:/Safebite/frontend/lib/widgets/result_bottom_sheet.dart)
- Replace Taylor series `.sin()` extension with `dart:math` `sin()` for correctness

#### [MODIFY] [pubspec.yaml](file:///d:/Safebite/frontend/pubspec.yaml)
- Add `google_fonts` dependency for Inter font family

---

## Verification Plan

### Automated
1. `flutter pub get` — no errors
2. `python -c "from nlp_engine import detect_restricted_ingredients; print('OK')"` — prints OK
3. `uvicorn main:app` — starts clean

### Manual
1. `flutter analyze` — no compilation errors
2. User sets Supabase URL + key in `app_config.dart`
3. User runs SQL schema in Supabase SQL Editor
4. `flutter run` — app launches on device/emulator
