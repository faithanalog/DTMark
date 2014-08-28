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
   * Padding in pixels between frames on the X axis
   */
  int padX;

  /**
   * Padding in pixels between frames on the Y axis
   */
  int padY;

  /**
   * The amount of time in milliseconds that a frame is displayed
   */
  int frameDuration;

  /**
   * Number of frames in the animation
   */
  int numFrames;

  /**
   * Starting frame of the animation
   */
  int startFrame;

  /**
   * Whether or not the animation will loop when it completes
   */
  bool loop;

  /**
   * Texture containing all frames of the animation
   */
  Texture animationFrames;

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
      this.startFrame = startFrame;
      this.padX = padX;
      this.padY = padY;
      this.loop = loop;

      _savedFrame = startFrame;
    }

  /**
   * Starts or resumes the animation
   */
  void play() {
    _animStart = new DateTime.now().millisecondsSinceEpoch - ((_savedFrame - startFrame) * frameDuration);
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
   * Resets the animation to the first frame
   */
  void stop() {
    _savedFrame = startFrame;
    _playing = false;
  }

  /**
   * Sets the current frame relative to [startFrame]. This means that to reset
   * the animation to the first frame, call setFrame(0).
   */
  void setFrame(int frame) {
    _savedFrame = frame + startFrame;
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
      int time = new DateTime.now().millisecondsSinceEpoch - _animStart;
      int duration = numFrames * frameDuration;
      int frame;
      if (loop) {
        frame = (numFrames * (time % duration)) ~/ duration + startFrame;
      } else {
        frame = Math.min(startFrame + numFrames - 1, (numFrames * time) ~/ duration + startFrame);
      }
      return frame;
    }
  }

  /**
   * X coordinate of the current frame in the frame texture
   */
  int get frameX {
    int curFrame = this.frame;
    int cellWidth = width + padX;
    //padX is added to the texture width because the padding is included
    //in the cell width, but the padding should not exist at the border of the texture.
    return curFrame % ((animationFrames.width + padX) ~/ cellWidth) * cellWidth;
  }

  /**
   * Y coordinate of the current frame in the frame texture
   */
  int get frameY {
    int curFrame = this.frame;
    int cellWidth = width + padX;
    int cellHeight = height + padY;
    //padX is added to the texture width because the padding is included
    //in the cell width, but the padding should not exist at the border of the texture.
    return curFrame ~/ ((animationFrames.width + padX) ~/ cellWidth) * cellHeight;
  }

}
