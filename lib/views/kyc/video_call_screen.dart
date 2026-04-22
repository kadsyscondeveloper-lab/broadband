// lib/views/kyc/video_call_screen.dart
//
// Full-screen Agora video call used for Video KYC verification.
//
// pubspec.yaml dependencies to add:
//   agora_rtc_engine: ^6.3.2
//   permission_handler: ^11.3.0

import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../theme/app_theme.dart';

class VideoCallCredentials {
  final String  appId;
  final String  channel;
  final String  token;
  final int     uid;
  final int     requestId;

  const VideoCallCredentials({
    required this.appId,
    required this.channel,
    required this.token,
    required this.uid,
    required this.requestId,
  });
}

class VideoCallScreen extends StatefulWidget {
  final VideoCallCredentials credentials;

  const VideoCallScreen({super.key, required this.credentials});

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  late RtcEngine _engine;

  bool _localJoined      = false;
  bool _remoteJoined     = false;
  bool _micMuted         = false;
  bool _cameraOff        = false;
  bool _isEngineReady    = false;
  bool _callEnded        = false;
  int? _remoteUid;

  // Timestamp for call duration
  DateTime? _callStart;

  @override
  void initState() {
    super.initState();
    _initCall();
  }

  @override
  void dispose() {
    _cleanup();
    super.dispose();
  }

  Future<void> _initCall() async {
    // 1. Request permissions
    await [Permission.camera, Permission.microphone].request();

    // 2. Create engine
    _engine = createAgoraRtcEngine();
    await _engine.initialize(RtcEngineContext(
      appId:        widget.credentials.appId,
      channelProfile: ChannelProfileType.channelProfileCommunication,
    ));

    // 3. Register event handlers
    _engine.registerEventHandler(RtcEngineEventHandler(
      onJoinChannelSuccess: (connection, elapsed) {
        setState(() { _localJoined = true; _callStart = DateTime.now(); });
      },
      onUserJoined: (connection, remoteUid, elapsed) {
        setState(() { _remoteJoined = true; _remoteUid = remoteUid; });
      },
      onUserOffline: (connection, remoteUid, reason) {
        setState(() { _remoteJoined = false; _remoteUid = null; });
        // Agent left — show ended screen after brief delay
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) _showCallEnded(reason: 'Agent disconnected');
        });
      },
      onError: (err, msg) {
        debugPrint('[Agora] Error $err: $msg');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Call error: $msg'), backgroundColor: Colors.red),
          );
        }
      },
    ));

    // 4. Enable video
    await _engine.enableVideo();
    await _engine.startPreview();

    setState(() => _isEngineReady = true);

    // 5. Join channel
    await _engine.joinChannel(
      token:       widget.credentials.token,
      channelId:   widget.credentials.channel,
      uid:         widget.credentials.uid,
      options:     const ChannelMediaOptions(
        autoSubscribeAudio: true,
        autoSubscribeVideo: true,
        publishCameraTrack: true,
        publishMicrophoneTrack: true,
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
      ),
    );
  }

  Future<void> _cleanup() async {
    await _engine.leaveChannel();
    await _engine.release();
  }

  void _showCallEnded({String? reason}) {
    setState(() => _callEnded = true);
  }

  Future<void> _endCall() async {
    await _cleanup();
    if (mounted) Navigator.of(context).pop();
  }

  void _toggleMic() async {
    _micMuted = !_micMuted;
    await _engine.muteLocalAudioStream(_micMuted);
    setState(() {});
  }

  void _toggleCamera() async {
    _cameraOff = !_cameraOff;
    await _engine.muteLocalVideoStream(_cameraOff);
    setState(() {});
  }

  void _flipCamera() async {
    await _engine.switchCamera();
  }

  String _elapsed() {
    if (_callStart == null) return '00:00';
    final diff = DateTime.now().difference(_callStart!);
    final m = diff.inMinutes.toString().padLeft(2, '0');
    final s = (diff.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_callEnded) return _CallEndedScreen(onBack: () => Navigator.pop(context));

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Remote video (full screen) ──────────────────────────────────
          _buildRemoteView(),

          // ── Local PiP video (bottom-right) ─────────────────────────────
          if (_isEngineReady)
            Positioned(
              right: 16,
              bottom: 130,
              child: _buildLocalView(),
            ),

          // ── Top bar ─────────────────────────────────────────────────────
          Positioned(
            top: 0, left: 0, right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(children: [
                      const Icon(Icons.security_rounded, color: AppColors.primary, size: 14),
                      const SizedBox(width: 6),
                      const Text(
                        'KYC Verification',
                        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ]),
                  ),
                  const Spacer(),
                  if (_localJoined)
                    _ElapsedTimer(callStart: _callStart),
                ]),
              ),
            ),
          ),

          // ── Waiting overlay ─────────────────────────────────────────────
          if (_localJoined && !_remoteJoined)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  const SizedBox(height: 20),
                  Text(
                    'Waiting for agent to join…',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Have your ID document ready',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

          if (!_localJoined)
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),

          // ── Bottom controls ─────────────────────────────────────────────
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(32, 16, 32, 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _ControlButton(
                      icon: _micMuted
                          ? Icons.mic_off_rounded
                          : Icons.mic_rounded,
                      label: _micMuted ? 'Unmute' : 'Mute',
                      active: !_micMuted,
                      onTap: _toggleMic,
                    ),
                    _EndCallButton(onTap: _endCall),
                    _ControlButton(
                      icon: _cameraOff
                          ? Icons.videocam_off_rounded
                          : Icons.videocam_rounded,
                      label: _cameraOff ? 'Start Cam' : 'Stop Cam',
                      active: !_cameraOff,
                      onTap: _toggleCamera,
                    ),
                    _ControlButton(
                      icon: Icons.flip_camera_ios_rounded,
                      label: 'Flip',
                      active: true,
                      onTap: _flipCamera,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Remote video ──────────────────────────────────────────────────────────

  Widget _buildRemoteView() {
    if (!_remoteJoined || _remoteUid == null) {
      return Container(
        color: const Color(0xFF0D0D0D),
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 90, height: 90,
              decoration: const BoxDecoration(
                  color: Color(0xFF1A1A2E), shape: BoxShape.circle),
              child: const Icon(Icons.person_rounded, color: Colors.white38, size: 48),
            ),
            const SizedBox(height: 16),
            const Text(
              'Speedonet Agent',
              style: TextStyle(color: Colors.white60, fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ]),
        ),
      );
    }

    return AgoraVideoView(
      controller: VideoViewController.remote(
        rtcEngine:  _engine,
        canvas:     VideoCanvas(uid: _remoteUid!),
        connection: RtcConnection(channelId: widget.credentials.channel),
      ),
    );
  }

  // ── Local video (PiP) ─────────────────────────────────────────────────────

  Widget _buildLocalView() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: 100, height: 140,
        child: _cameraOff
            ? Container(
          color: const Color(0xFF1A1A2E),
          child: const Center(
            child: Icon(Icons.videocam_off_rounded, color: Colors.white38, size: 28),
          ),
        )
            : AgoraVideoView(
          controller: VideoViewController(
            rtcEngine: _engine,
            canvas:    const VideoCanvas(uid: 0),
          ),
        ),
      ),
    );
  }
}

// ── Elapsed timer widget ──────────────────────────────────────────────────────

class _ElapsedTimer extends StatefulWidget {
  final DateTime? callStart;
  const _ElapsedTimer({required this.callStart});

  @override
  State<_ElapsedTimer> createState() => _ElapsedTimerState();
}

class _ElapsedTimerState extends State<_ElapsedTimer> {
  late final _ticker = Stream.periodic(const Duration(seconds: 1));

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _ticker,
      builder: (context, _) {
        if (widget.callStart == null) return const SizedBox();
        final diff = DateTime.now().difference(widget.callStart!);
        final m = diff.inMinutes.toString().padLeft(2, '0');
        final s = (diff.inSeconds % 60).toString().padLeft(2, '0');
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.8),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(children: [
            Container(
              width: 6, height: 6,
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text('$m:$s',
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
          ]),
        );
      },
    );
  }
}

// ── Control buttons ───────────────────────────────────────────────────────────

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
            color: active ? Colors.white.withOpacity(0.2) : Colors.white.withOpacity(0.08),
            shape: BoxShape.circle,
            border: Border.all(
              color: active ? Colors.white.withOpacity(0.3) : Colors.white.withOpacity(0.1),
            ),
          ),
          child: Icon(icon, color: active ? Colors.white : Colors.white38, size: 24),
        ),
        const SizedBox(height: 6),
        Text(label,
            style: TextStyle(
                color: active ? Colors.white70 : Colors.white30,
                fontSize: 11,
                fontWeight: FontWeight.w500)),
      ]),
    );
  }
}

class _EndCallButton extends StatelessWidget {
  final VoidCallback onTap;
  const _EndCallButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 68, height: 68,
          decoration: const BoxDecoration(
              color: Colors.red, shape: BoxShape.circle),
          child: const Icon(Icons.call_end_rounded, color: Colors.white, size: 30),
        ),
        const SizedBox(height: 6),
        const Text('End', style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

// ── Call ended screen ─────────────────────────────────────────────────────────

class _CallEndedScreen extends StatelessWidget {
  final VoidCallback onBack;
  const _CallEndedScreen({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 90, height: 90,
              decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.call_end_rounded, color: Colors.red, size: 44),
            ),
            const SizedBox(height: 24),
            const Text('Call Ended',
                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            const Text(
              'The verification call has ended.\nYour KYC status will be updated shortly.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 36),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onBack,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Back to KYC',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}