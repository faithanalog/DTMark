part of dtmark;

/**
 * An oscillator that plays a waveform at a given frequency
 */
class Oscillator extends PlayableAudio {

  /**
   * Wave type, can be sine, square, sawtooth, or triangle
   */
  String type;

  /**
   * Playback frequency in hertz
   */
  int frequency;

  /**
   * Duration of the sound in seconds. If -1, will play back indefinetly
   */
  num duration;

  Oscillator(this.type, this.frequency, AudioEngine engine,
    {this.duration: -1}): super(engine);

  @override
  WebAudio.AudioSourceNode createSource() {
    var src = engine.ctx.createOscillator();
    src.type = type;
    src.frequency.value = frequency;
    return src;
  }

  @override
  WebAudio.AudioSourceNode play([num delay=0]) {
    var src = createSource();
    src.connectNode(engine.dest);
    src.start(delay + engine.time);
    if (duration > 0) {
      src.stop(duration + delay + engine.time);
    }
    return src;
  }

  @override
  WebAudio.AudioSourceNode playLooping([num delay=0]) {
    var src = createSource();
    src.connectNode(engine.dest);
    src.start(delay + engine.time);
    return src;
  }
}

/**
 * A custom oscillator that lets you define your own waveform
 */
class CustomOscillator extends Oscillator {

  /**
   * The custom wave created from the values passed in when creating this
   * oscillator
   */
  WebAudio.PeriodicWave wave;

  /**
   * Creates a new CustomOscillator using [real] and [imag] as
   * the table of values for creating the wave. They are
   * coeffecients for the reverse fourrier transform (maybe?).
   */
  CustomOscillator(Float32List real, Float32List imag, int freq, AudioEngine engine,
    {num duration: -1}):super("custom", freq, engine, duration: duration) {
      wave = engine.ctx.createPeriodicWave(real, imag);
    }

  @override
  WebAudio.AudioSourceNode createSource() {
    var src = super.createSource();
    src.setPeriodicWave(wave);
    return src;
  }
}
