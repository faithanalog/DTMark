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
   * Duration of the sound. If -1, will play back indefinetly
   */
  int duration;

  Oscillator(this.type, this.frequency, AudioEngine engine,
    {this.duration: -1}): super(engine);

  @override
  WebAudio.AudioSourceNode createSource() {
    var src = engine.ctx.createOscillator();
    src.type = type;
    src.frequency = frequency;
    return src;
  }

  @override
  WebAudio.AudioSourceNode play() {
    var src = createSource();
    src.connectNode(engine.dest);
    src.start(0);
    if (duration > 0) {
      src.stop(duration / 1000);
    }
    return src;
  }

  @override
  WebAudio.AudioSourceNode playLooping() {
    var src = createSource();
    src.connectNode(engine.dest);
    src.start(0);
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
    {int duration: -1}):super("custom", freq, engine, duration: duration) {
      wave = engine.ctx.createPeriodicWave(real, imag);
    }

  @override
  WebAudio.AudioSourceNode createSource() {
    var src = super.createSource();
    src.setPeriodicWave(wave);
    return src;
  }
}
