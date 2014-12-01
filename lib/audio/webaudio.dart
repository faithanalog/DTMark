part of dtmark;

/**
 * Wrapper around a WebAudio AudioContext which is used by DTMark audio classes.
 */
class AudioEngine {

  WebAudio.AudioContext ctx;
  WebAudio.AudioNode dest;

  WebAudio.GainNode _gain;

  AudioEngine() {
    ctx = new WebAudio.AudioContext();
    _gain = ctx.createGain();
    dest = _gain;
    dest.connectNode(ctx.destination);
    volume = 1.0;
  }

  set volume(double vol) => _gain.gain.value = vol;

  double get volume => _gain.gain.value;

  /**
   * Current time of the AudioContext in seconds.
   * Used for specifying 'when' for playing sounds
   */
  double get time => ctx.currentTime;

  static bool _webAudioSupport = null;
  /**
   * Whether or not the browser supports WebAudio. Applications should
   * gracefully handle a lack of WebAudio support by not playing
   * audio, instead of simply crashing. However, it is likely
   * that any browser supporting WebGL also supports WebAudio.
   */
  static bool get webAudioSupport {
    if (_webAudioSupport == null) {
      var jswindow = new JsObject.fromBrowserObject(window);
      _webAudioSupport = jswindow.hasProperty("AudioContext") ||
        jswindow.hasProperty("webkitAudioContext");
    }
    return _webAudioSupport;
  }

}

/**
 * Base interface for audio classes
 */
abstract class PlayableAudio {

  /**
   * The AudioEngine associated with this audio clip
   */
  AudioEngine engine;

  PlayableAudio(this.engine);

  /**
   * Creates an AudioSourceNode from this audio clip
   */
  WebAudio.AudioSourceNode createSource();

  Future<PlayableAudio> get onLoad => new Future.value(this);

  /**
   * Creates an AudioSourceNode from this audio clip and begins playing it.
   * If [when] is 0, starts playing immediately, otherwise plays at
   * the time [when] (see [AudioEngine.time]).
   */
  WebAudio.AudioSourceNode play([num when=0]);

  /**
   * Creates an AudioSourceNode from this audio clip and begins playing and looping it.
   * If [when] is 0, starts playing immediately, otherwise plays at
   * the time [when] (see [AudioEngine.time]).
   */
  WebAudio.AudioSourceNode playLooping([num when=0]);
}

/**
 * Audio source that is streamed in while playing using AudioElement instead of
 * being preloaded. This is useful for longer audio clips such as music.
 */
class AudioStream extends PlayableAudio {

  /**
   * HTML AudioElement which is the source of the audio data
   */
  AudioElement elem;
  Completer<PlayableAudio> _loadCompleter = new Completer();

  AudioStream(String path, AudioEngine engine, [bool wav = false]): super(engine) {
    elem = AudioStreaming.loadAudio(path, wav: wav);
    elem.onCanPlayThrough.first.then((evt) {
      _loadCompleter.complete(this);
    });
  }

  @override
  WebAudio.MediaElementAudioSourceNode createSource() {
    var src = engine.ctx.createMediaElementSource(elem);
    return src;
  }

  @override
  WebAudio.MediaElementAudioSourceNode play([num when=0]) {
    return _playAtTime(false, when);
  }

  @override
  WebAudio.MediaElementAudioSourceNode playLooping([num when=0]) {
    return _playAtTime(true, when);
  }

  WebAudio.MediaElementAudioSourceNode _playAtTime(bool loop, num when) {
    var src = createSource();
    src.connectNode(engine.dest);
    if (elem.currentTime > 0) {
      elem.currentTime = 0;
    }
    elem.loop = loop;
    if (when > 0) {
      int offs = ((when - engine.time) * 1000).toInt();
      if (offs > 0) {
        new Timer(new Duration(milliseconds: offs), () {
          elem.play();
        });
      }
    } else {
      elem.play();
    }
    return src;
  }


  @override
  Future<PlayableAudio> get onLoad => _loadCompleter.future;
}

/**
 * Audio source which is fully loaded before playing. Audio data is stored
 * in a WebAudio AudioBuffer.
 */
class Sound extends PlayableAudio {

  /**
   * AudioBuffer which is the source of the audio data
   */
  WebAudio.AudioBuffer buffer;
  Completer<PlayableAudio> _loadCompleter = new Completer();

  /**
   * Loads the [audioData] for playback
   */
  Sound(ByteBuffer audioData, AudioEngine engine): super(engine) {
    engine.ctx.decodeAudioData(audioData).then((buffer) {
      this.buffer = buffer;
      _loadCompleter.complete(this);
    });
  }

  /**
   * Loads the audio file from [path], where path is the path
   * to the audio file without a file extension. Automatically
   * determines whether to use mp3 or ogg. If [wav] is set to
   * true, will load wav instead of trying mp3 or ogg.
   */
  Sound.load(String path, AudioEngine engine, [bool wav = false]): super(engine) {
    if (wav) {
      path += ".wav";
    } else if (BrowserDetect.browser.isSafari || BrowserDetect.browser.isIe) {
      path += ".mp3";
    } else if (BrowserDetect.browser.isChrome || BrowserDetect.browser.isFirefox || BrowserDetect.browser.isOpera) {
      path += ".ogg";
    } else {
      path += ".wav";
    }
    var req = new HttpRequest();
    req.open('GET', path);
    req.responseType = 'arraybuffer';
    req.onLoad.first.then((evt) {
      engine.ctx.decodeAudioData(req.response).then((buffer) {
        this.buffer = buffer;
        _loadCompleter.complete(this);
      }, onError: (err) {
        print("Error loading Sound from $path: $err");
        _loadCompleter.completeError(err);
      });
    });
    req.send();
  }

  @override
  WebAudio.AudioBufferSourceNode createSource() {
    var src = engine.ctx.createBufferSource();
    src.buffer = buffer;
    return src;
  }

  @override
  WebAudio.AudioBufferSourceNode play([num when=0]) {
    var src = createSource();
    src.connectNode(engine.dest);
    src.start(when);
    return src;
  }

  @override
  WebAudio.AudioBufferSourceNode playLooping([num when=0]) {
    var src = createSource();
    src.connectNode(engine.dest);
    src.loop = true;
    src.start(when);
    return src;
  }


  @override
  Future<PlayableAudio> get onLoad => _loadCompleter.future;

}
