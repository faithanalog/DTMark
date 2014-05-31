part of dtmark;

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
  
}

abstract class PlayableAudio {
  AudioEngine engine;
  
  PlayableAudio(this.engine);
  
  WebAudio.AudioSourceNode createSource();
  
  Future<PlayableAudio> onLoad();
  
  WebAudio.AudioSourceNode play();
  
  WebAudio.AudioSourceNode playLooping();
}

class AudioStream extends PlayableAudio {
  
  AudioElement elem;
  Completer<PlayableAudio> _loadCompleter = new Completer();
  
  AudioStream(String path, AudioEngine engine, [bool wav = false]): super(engine) {
    elem = AudioStreaming.loadAudio(path, wav: wav);
    elem.onLoadStart.first.then((evt) {
      _loadCompleter.complete(this);
    });
  }
  
  @override
  WebAudio.MediaElementAudioSourceNode createSource() {
    var src = engine.ctx.createMediaElementSource(elem);
    return src;
  }
  
  @override
  WebAudio.MediaElementAudioSourceNode play() {
    var src = createSource();
    src.connectNode(engine.dest);
    if (elem.currentTime > 0) {
      elem.currentTime = 0;
    }
    elem.loop = false;
    elem.play();
    return src;
  }
  
  @override
  WebAudio.MediaElementAudioSourceNode playLooping() {
    var src = createSource();
    src.connectNode(engine.dest);
    if (elem.currentTime > 0) {
      elem.currentTime = 0;
    }
    elem.loop = true;
    elem.play();
    return src;
  }
  
  
  @override
  Future<PlayableAudio> onLoad() {
    return _loadCompleter.future;
  }
}

class Sound extends PlayableAudio {
  
  WebAudio.AudioBuffer buffer;
  Completer<PlayableAudio> _loadCompleter = new Completer();
    
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
  WebAudio.AudioBufferSourceNode play() {
    var src = createSource();
    src.connectNode(engine.dest);
    src.start(0);
    return src;
  }
  
  @override
  WebAudio.AudioBufferSourceNode playLooping() {
    var src = createSource();
    src.connectNode(engine.dest);
    src.loop = true;
    src.start(0);
    return src;
  }
  
  
  @override
  Future<PlayableAudio> onLoad() {
    return _loadCompleter.future;
  }
  
}