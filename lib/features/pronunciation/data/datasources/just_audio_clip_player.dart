import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';
import 'package:yaani_eh/features/pronunciation/domain/repositories/pronunciation_repository.dart';

/// [ClipPlayer] on just_audio: plays local files only (clips are
/// downloaded by the repository over HTTPS first), so no cleartext proxy.
///
/// The audio session is set up for short speech: other apps' music is
/// ducked, not stopped, and comes back when the name ends. Playing ignores
/// the silent switch on iOS, because the reader asked for it.
class JustAudioClipPlayer implements ClipPlayer {
  AudioPlayer? _player;
  AudioSession? _session;

  static final AudioSessionConfiguration _speech =
      const AudioSessionConfiguration.speech().copyWith(
        avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.duckOthers,
        avAudioSessionSetActiveOptions:
            AVAudioSessionSetActiveOptions.notifyOthersOnDeactivation,
        androidAudioFocusGainType:
            AndroidAudioFocusGainType.gainTransientMayDuck,
        androidWillPauseWhenDucked: false,
      );

  @override
  Future<void> play(String filePath, {required double speed}) async {
    final session = _session ??= await _configure();
    final player = _player ??= AudioPlayer();
    await player.stop();
    await player.setFilePath(filePath);
    await player.setSpeed(speed);
    try {
      // Completes when the clip ends, or when stop() is called.
      await player.play();
    } finally {
      await player.stop();
      // Lets ducked music come back up.
      await session.setActive(false);
    }
  }

  @override
  Future<void> stop() async {
    await _player?.stop();
  }

  static Future<AudioSession> _configure() async {
    final session = await AudioSession.instance;
    await session.configure(_speech);
    return session;
  }
}
