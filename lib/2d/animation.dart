part of dtmark;

/**
 * A basic animation that cycles through a sequence of frames.
 */
class SpriteAnimation {

  /**
   * Width of the sprite
   */
  int width;

  /**
   * Height of the sprite
   */
  int height;

  /**
   * The amount of time in milliseconds that a frame is displayed
   */
  int frameDuration;

  /**
   * Number of frames in the animation
   */
  int numFrames;

  /**
   * Whether or not the animation will loop when it completes
   */
  bool loop;

  /**
   * Texture containing all frames of the animation
   */
  Texture animationFrames;

  /**
   * Texture regions for the frames used in the animation.
   */
  List<TextureRegion> frames;

  /**
   * Returned for the current frame if the current frame is null (texture still loading)
   */
  TextureRegion _blankFrame;

  //When the animation was started
  int _animStart = 0;

  //When the animation is paused or stops, the frame to display is saved here.
  int _savedFrame = 0;

  //Is the animation playing
  bool _playing = false;

  /**
   * Constructs a new SpriteAnimation that displays each frame for [frameDuration] milliseconds.
   * All frames must be [width] x [height] in size. [animationFrames] provides
   * a texture that has all frames of the animation. Frames will be read from
   * left to right, and then top to bottom. [padX] and [padY] define the number
   * of pixels between each frame in the texture, and default to 0. This padding
   * is assumed to not exist at the edges of the texture. [numFrames] defines
   * the number of frames in the animation. [startFrame] defines the first
   * frame of the animation.
   */
  SpriteAnimation(this.width, this.height, this.frameDuration, this.numFrames, this.animationFrames,
    {int startFrame: 0, int padX: 0, int padY: 0, bool loop: true}) {
      frames = new List(numFrames);
      _blankFrame = new TextureRegion(animationFrames, 0, 0, width, height);
      animationFrames.onLoad.then((_) {
        for (int i = 0; i < numFrames; i++) {
          int cellW = width + padX, cellH = height + padX;
          int frm = i + startFrame;
          int frmX = frm % ((animationFrames.width + padX) ~/ cellW) * cellW;
          int frmY = frm ~/ ((animationFrames.width + padX) ~/ cellW) * cellH;
          frames[i] = new TextureRegion(animationFrames, frmX, frmY, width, height);
        }
      });
      this.loop = loop;
      _savedFrame = 0;
    }

  /**
   * Starts or resumes the animation
   */
  void play() {
    _animStart = BaseGame.frameTime - (_savedFrame * frameDuration);
    _savedFrame = 0;
    _playing = true;
  }


  /**
   * Pauses the animation on the current frame
   */
  void pause() {
    _savedFrame = this.frame;
    _playing = false;
  }

  /**
   * Resets the animation to the first frame and stops the animation
   */
  void stop() {
    _savedFrame = 0;
    _playing = false;
  }

  /**
   * Restarts the animation at frame 0
   */
  void restart() {
    stop();
    play();
  }

  /**
   * Sets the current frame relative to [startFrame]. This means that to reset
   * the animation to the first frame, call setFrame(0).
   */
  void setFrame(int frame) {
    _savedFrame = frame;
    if (_playing) {
      play(); //Fix up the _animStart time
    }
  }

  /**
   * Current frame of the animation.
   */
  int get frame {
    if (!_playing) {
      return _savedFrame;
    } else {
      int time = BaseGame.frameTime - _animStart;
      int duration = numFrames * frameDuration;
      int frame;
      if (loop) {
        frame = (numFrames * (time % duration)) ~/ duration;
      } else {
        frame = Math.min(numFrames - 1, (numFrames * time) ~/ duration);
      }
      return frame;
    }
  }

  /**
   * Current texture region of the animation
   */
  TextureRegion get texRegion {
    TextureRegion frm = frames[frame];
    if (frm == null) {
      return _blankFrame;
    }
    return frames[frame];
  }
}
