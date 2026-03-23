// lib/widgets/home_tutorial.dart
//
// Defines every coach-mark step for the home screen first-launch tutorial.
// Uses the `tutorial_coach_mark` package.
//
// Usage (from _HomeScreenState):
//   HomeTutorial(context: context, keys: _tutorialKeys).show(
//     onFinish: () => TutorialService().markHomeTutorialSeen(),
//     onSkip:   () => TutorialService().markHomeTutorialSeen(),
//   );

import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

// ── Key bag ────────────────────────────────────────────────────────────────────
// All GlobalKeys the home screen needs to expose to the tutorial.

class HomeTutorialKeys {
  final GlobalKey menu          = GlobalKey();
  final GlobalKey notifications = GlobalKey();
  final GlobalKey wallet        = GlobalKey();
  final GlobalKey manageServices = GlobalKey();
  final GlobalKey payBills      = GlobalKey();
  final GlobalKey newPlan       = GlobalKey();
  final GlobalKey kyc           = GlobalKey();
  final GlobalKey referEarn     = GlobalKey();
}

// ── Tutorial builder ──────────────────────────────────────────────────────────

class HomeTutorial {
  final BuildContext context;
  final HomeTutorialKeys keys;

  HomeTutorial({required this.context, required this.keys});

  void show({
    required VoidCallback onFinish,
    required VoidCallback onSkip,
  }) {
    final targets = _buildTargets();
    if (targets.isEmpty) return;

    TutorialCoachMark(
      targets:            targets,
      colorShadow:        const Color(0xFF1A1A2E),
      opacityShadow:      0.85,
      paddingFocus:       10,
      hideSkip:           false,
      alignSkip:          Alignment.bottomRight,
      textSkip:           'SKIP',
      textStyleSkip: const TextStyle(
        color:      Colors.white70,
        fontSize:   14,
        fontWeight: FontWeight.w600,
      ),
      onFinish: onFinish,
      onSkip:   () { onSkip(); return true; },
    ).show(context: context);
  }

  // ── Step definitions ────────────────────────────────────────────────────────

  List<TargetFocus> _buildTargets() => [
    // 1. Hamburger menu
    _step(
      key:    keys.menu,
      shape:  ShapeLightFocus.Circle,
      title:  'Main Menu',
      body:   'Tap here to open the side menu — access your profile, plans, refer & earn, and more.',
      align:  ContentAlign.bottom,
    ),

    // 2. Notifications
    _step(
      key:    keys.notifications,
      shape:  ShapeLightFocus.Circle,
      title:  'Notifications',
      body:   'Stay up to date with plan activations, wallet credits, and support updates.',
      align:  ContentAlign.bottom,
    ),

    // 3. Wallet balance
    _step(
      key:    keys.wallet,
      shape:  ShapeLightFocus.RRect,
      title:  'Your Wallet',
      body:   'Your current wallet balance. Tap to recharge and use it for plan purchases.',
      align:  ContentAlign.bottom,
    ),

    // 4. Manage Services card
    _step(
      key:    keys.manageServices,
      shape:  ShapeLightFocus.RRect,
      title:  'Manage Services',
      body:   'Quick shortcuts to everything you need — bills, plans, KYC, and more.',
      align:  ContentAlign.bottom,
    ),

    // 5. Pay Bills
    _step(
      key:    keys.payBills,
      shape:  ShapeLightFocus.Circle,
      title:  'Pay Bills',
      body:   'Pay your broadband and utility bills in seconds — right here.',
      align:  ContentAlign.bottom,
    ),

    // 6. New Plan
    _step(
      key:    keys.newPlan,
      shape:  ShapeLightFocus.Circle,
      title:  'Browse Plans',
      body:   'Explore and subscribe to our internet plans — monthly, quarterly, or annual.',
      align:  ContentAlign.bottom,
    ),

    // 7. KYC
    _step(
      key:    keys.kyc,
      shape:  ShapeLightFocus.Circle,
      title:  'KYC Verification',
      body:   'Complete your KYC to unlock all features and get faster support.',
      align:  ContentAlign.bottom,
    ),

    // 8. Refer & Earn (features carousel)
    _step(
      key:    keys.referEarn,
      shape:  ShapeLightFocus.RRect,
      title:  'Refer & Earn',
      body:   'Share your referral link with friends and earn exciting rewards every time they sign up!',
      align:  ContentAlign.top,
    ),
  ];

  // ── Helper ──────────────────────────────────────────────────────────────────

  TargetFocus _step({
    required GlobalKey     key,
    required String        title,
    required String        body,
    required ContentAlign  align,
    ShapeLightFocus        shape = ShapeLightFocus.RRect,
    double                 radius = 12,
  }) {
    return TargetFocus(
      identify: title,
      keyTarget: key,
      shape:     shape,
      radius:    radius,
      enableOverlayTab: true,          // tap anywhere on overlay to advance
      contents: [
        TargetContent(
          align: align,
          builder: (ctx, controller) => _CoachCard(
            title:      title,
            body:       body,
            onNext:     controller.next,
          ),
        ),
      ],
    );
  }
}

// ── Coach-mark card widget ────────────────────────────────────────────────────

class _CoachCard extends StatelessWidget {
  final String       title;
  final String       body;
  final VoidCallback onNext;

  const _CoachCard({
    required this.title,
    required this.body,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset:     const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize:       MainAxisSize.min,
        children: [
          // Title row
          Row(children: [
            Container(
              width: 4, height: 20,
              decoration: BoxDecoration(
                color:        const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize:   16,
                fontWeight: FontWeight.w800,
                color:      Color(0xFF1A1A2E),
              ),
            ),
          ]),
          const SizedBox(height: 10),

          // Body
          Text(
            body,
            style: const TextStyle(
              fontSize: 13,
              color:    Color(0xFF555577),
              height:   1.5,
            ),
          ),
          const SizedBox(height: 16),

          // Next button
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: onNext,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color:        const Color(0xFF1A1A2E),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Text(
                  'Next  →',
                  style: TextStyle(
                    color:      Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize:   13,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
}