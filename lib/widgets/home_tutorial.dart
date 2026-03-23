// lib/widgets/home_tutorial.dart

import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

// ── Key bag ────────────────────────────────────────────────────────────────────

class HomeTutorialKeys {
  final GlobalKey menu           = GlobalKey();
  final GlobalKey notifications  = GlobalKey();
  final GlobalKey wallet         = GlobalKey();
  final GlobalKey manageServices = GlobalKey();
  final GlobalKey payBills       = GlobalKey();
  final GlobalKey newPlan        = GlobalKey();
  final GlobalKey kyc            = GlobalKey();
  final GlobalKey referEarn      = GlobalKey();
}

// ── Tutorial builder ──────────────────────────────────────────────────────────

class HomeTutorial {
  final BuildContext     context;
  final HomeTutorialKeys keys;
  final ScrollController scrollController;

  HomeTutorial({
    required this.context,
    required this.keys,
    required this.scrollController,
  });

  void show({
    required VoidCallback onFinish,
    required VoidCallback onSkip,
  }) {
    final targets = _buildTargets();
    if (targets.isEmpty) return;

    TutorialCoachMark(
      targets:       targets,
      colorShadow:   const Color(0xFF1A1A2E),
      opacityShadow: 0.85,
      paddingFocus:  10,
      hideSkip:      false,
      alignSkip:     Alignment.bottomRight,
      textSkip:      'SKIP',
      textStyleSkip: const TextStyle(
        color:      Colors.white70,
        fontSize:   14,
        fontWeight: FontWeight.w600,
      ),
      onFinish: onFinish,
      onSkip:   () { onSkip(); return true; },
    ).show(context: context);
  }

  // ── Scroll helper ─────────────────────────────────────────────────────────
  //
  // We scroll to maxScrollExtent - 300 instead of all the way to the bottom.
  // This leaves the Features section roughly in the center of the screen,
  // so ContentAlign.top has enough vertical space above it to show the card.

  Future<void> _scrollToFeatures() async {
    await Future.delayed(const Duration(milliseconds: 400));
    if (!scrollController.hasClients) return;

    final max    = scrollController.position.maxScrollExtent;
    final target = (max - 200).clamp(0.0, max);

    await scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 600),
      curve:    Curves.easeInOut,
    );

    // Extra frame so the Features widget finishes painting before
    // tutorial_coach_mark measures its RenderBox.
    await Future.delayed(const Duration(milliseconds: 300));
  }

  // ── Step definitions ───────────────────────────────────────────────────────

  List<TargetFocus> _buildTargets() => [
    _step(
      key:   keys.menu,
      shape: ShapeLightFocus.Circle,
      title: 'Main Menu',
      body:  'Tap here to open the side menu — access your profile, plans, refer & earn, and more.',
      align: ContentAlign.bottom,
    ),
    _step(
      key:   keys.notifications,
      shape: ShapeLightFocus.Circle,
      title: 'Notifications',
      body:  'Stay up to date with plan activations, wallet credits, and support updates.',
      align: ContentAlign.bottom,
    ),
    _step(
      key:   keys.wallet,
      shape: ShapeLightFocus.RRect,
      title: 'Your Wallet',
      body:  'Your current wallet balance. Tap to recharge and use it for plan purchases.',
      align: ContentAlign.bottom,
    ),
    _step(
      key:   keys.manageServices,
      shape: ShapeLightFocus.RRect,
      title: 'Manage Services',
      body:  'Quick shortcuts to everything you need — bills, plans, KYC, and more.',
      align: ContentAlign.bottom,
    ),
    _step(
      key:   keys.payBills,
      shape: ShapeLightFocus.Circle,
      title: 'Pay Bills',
      body:  'Pay your broadband and utility bills in seconds — right here.',
      align: ContentAlign.bottom,
    ),
    _step(
      key:   keys.newPlan,
      shape: ShapeLightFocus.Circle,
      title: 'Browse Plans',
      body:  'Explore and subscribe to internet plans — monthly, quarterly, or annual.',
      align: ContentAlign.bottom,
    ),
    // KYC step — Next scrolls to Features THEN advances
    _stepWithBeforeNext(
      key:        keys.kyc,
      shape:      ShapeLightFocus.Circle,
      title:      'KYC',
      body:       'Complete your KYC to unlock all features and get faster support.',
      align:      ContentAlign.bottom,
      beforeNext: _scrollToFeatures,
    ),
    // Features section is now mid-screen → card appears above with room to spare
    _step(
      key:   keys.referEarn,
      shape: ShapeLightFocus.RRect,
      title: 'Refer & Earn',
      body:  'Share your referral link with friends and earn exciting rewards every time they sign up!',
      align: ContentAlign.top, // card sits above the spotlight
    ),
  ];

  // ── Helpers ────────────────────────────────────────────────────────────────

  TargetFocus _step({
    required GlobalKey    key,
    required String       title,
    required String       body,
    required ContentAlign align,
    ShapeLightFocus       shape  = ShapeLightFocus.RRect,
    double                radius = 12,
  }) {
    return TargetFocus(
      identify:         title,
      keyTarget:        key,
      shape:            shape,
      radius:           radius,
      enableOverlayTab: true,
      contents: [
        TargetContent(
          align:   align,
          builder: (ctx, controller) => _CoachCard(
            title:  title,
            body:   body,
            onNext: controller.next,
          ),
        ),
      ],
    );
  }

  TargetFocus _stepWithBeforeNext({
    required GlobalKey              key,
    required String                 title,
    required String                 body,
    required ContentAlign           align,
    required Future<void> Function() beforeNext,
    ShapeLightFocus                 shape  = ShapeLightFocus.RRect,
    double                          radius = 12,
  }) {
    return TargetFocus(
      identify:         title,
      keyTarget:        key,
      shape:            shape,
      radius:           radius,
      enableOverlayTab: false, // only the Next button advances
      contents: [
        TargetContent(
          align:   align,
          builder: (ctx, controller) => _CoachCard(
            title:  title,
            body:   body,
            onNext: () async {
              await beforeNext();  // scroll completes first
              controller.next();   // then spotlight advances
            },
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
          Text(
            body,
            style: const TextStyle(
              fontSize: 13,
              color:    Color(0xFF555577),
              height:   1.5,
            ),
          ),
          const SizedBox(height: 16),
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