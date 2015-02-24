part of dtmark;

/**
 * Function which takes in a time value T in seconds, and a channel and returns an amplitude from -1 to 1.
 */
typedef double AudioGeneratorFunc(double t, int channel);

class AudioGenerator extends PlayableAudio {
  
  /**
   * Generator function used to generate audio data
   */
  AudioGeneratorFunc gen;
  
  /**
   * Buffer size when creating processors. Leave null for default
   */
  int bufferSize;
  
  /**
   * Number of output channels
   */
  int channels;
  
  /**
   * Duration. Null duration implies that it plays indefinitely.
   */
  double duration;
  
  AudioGenerator(AudioEngine engine, this.gen, {this.channels: 1, this.bufferSize: null, this.duration: null}): super(engine);

  @override
  WebAudio.AudioSourceNode createSource() {
    var src = engine.ctx.createScriptProcessor(bufferSize, 0, channels);
    
    //onaudioprocess doesn't exist for some reason.
    src.on['audioprocess'].listen((WebAudio.AudioProcessingEvent evt) {
      var out = evt.outputBuffer;
      var timeStep = 1 / out.sampleRate;
      
      for (var c = 0; c < out.numberOfChannels; c++) {
        var chan = out.getChannelData(c);
        for (var s = 0; s < chan.length; s++) {
          var t = evt.playbackTime + timeStep * s;
          chan[s] = gen(t, c);
        }
      }
    });
    

    return src;
  }

  @override
  WebAudio.AudioSourceNode play([num when=0]) {
    var src = createSource();
    src.connectNode(engine.dest);
    src.start(when);
    if (duration != null) {
      src.stop(when + duration);
    }
    return src;
  }

  @override
  WebAudio.AudioSourceNode playLooping([num when=0]) {
    var src = createSource();
    src.connectNode(engine.dest);
    src.start(when);
    return src;
  }
  
}