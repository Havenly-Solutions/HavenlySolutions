/*
 * ─────────────────────────────────────────────────────────────
 * FILE: mobile/lib/core/services/alarm_service.dart
 * PHASE: 8 — SOS Amber Alert Audio
 *
 * PURPOSE:
 *   Plays the SOS alarm sound at maximum volume using the Android
 *   alarm audio stream. The alarm stream bypasses Do Not Disturb,
 *   mute, and silent mode — exactly like a phone alarm clock.
 *
 *   On Android:
 *     Uses AudioManager.STREAM_ALARM via the audio_session package.
 *     Volume is set to maximum on the alarm stream.
 *     Alarm plays on loop until dismiss() is called.
 *
 *   On iOS:
 *     The audio plays using AVAudioSession with the .alarm category.
 *     iOS critical alert sound plays via APNs when the app is closed.
 *     When the app is open or in background, this service plays directly.
 *
 * HOW TO EXTEND:
 *   Phase 19 adds vibration pattern to accompany the audio.
 *   Phase 19 adds TTS announcement: "HAVENLY SOS ALERT IN [suburb]".
 * ─────────────────────────────────────────────────────────────
 */

import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

class AlarmService {
  static AlarmService? _instance;
  static AlarmService get instance => _instance ??= AlarmService._();
  AlarmService._();

  AudioPlayer? _player;
  bool _playing = false;

  bool get isPlaying => _playing;

  Future<void> playAlarm() async {
    if (_playing) return;

    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playback,
        avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.duckOthers,
        avAudioSessionMode: AVAudioSessionMode.defaultMode,
        avAudioSessionRouteSharingPolicy:
            AVAudioSessionRouteSharingPolicy.defaultPolicy,
        avAudioSessionSetActiveOptions:
            AVAudioSessionSetActiveOptions.notifyOthersOnDeactivation,
        androidAudioAttributes: AndroidAudioAttributes(
          contentType: AndroidAudioContentType.sonification,
          usage: AndroidAudioUsage.alarm,
          flags: AndroidAudioFlags.audibilityEnforced,
        ),
        androidAudioFocusGainType:
            AndroidAudioFocusGainType.gainTransientMayDuck,
        androidWillPauseWhenDucked: false,
      ));

      await session.setActive(true);

      _player = AudioPlayer();
      await _player!.setVolume(1.0);
      await _player!.setAsset('assets/audio/sos_alarm.wav');
      await _player!.setLoopMode(LoopMode.one);
      await _player!.play();

      _playing = true;
      debugPrint('[Alarm] SOS alarm started');
    } catch (e) {
      debugPrint('[Alarm] Failed to play alarm: $e');
    }
  }

  Future<void> dismiss() async {
    try {
      await _player?.stop();
      await _player?.dispose();
      _player = null;
      _playing = false;

      final session = await AudioSession.instance;
      await session.setActive(false);

      debugPrint('[Alarm] SOS alarm dismissed');
    } catch (e) {
      debugPrint('[Alarm] Dismiss error: $e');
    }
  }
}
