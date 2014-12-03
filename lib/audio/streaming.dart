part of dtmark;

/**
 * Utilities for loading AudioElements, auto-selecting filetype based on browser capabilitites.
 */
class AudioStreaming {
  /**
   * Loads the audio element from path, selecting the first supported type in
   * order of mp3, ogg and wav. the [path] should not include a file extension.
   * If [typeOverride] is set, will load audio from [path].[typeOverride].
   */
  static AudioElement loadAudio(String path, [String typeOverride = ""]) {
    var elem = new AudioElement();
    if (typeOverride.isNotEmpty) {
      path += "." + typeOverride;
    } else if (BrowserDetect.browser.isSafari || BrowserDetect.browser.isIe) {
      path += ".mp3";
    } else if (BrowserDetect.browser.isChrome || BrowserDetect.browser.isFirefox || BrowserDetect.browser.isOpera) {
      path += ".ogg";
    } else {
      path += ".wav";
    }
    elem.src = path;
    elem.load();
    return elem;
  }

  /**
   * Loads the audio element from path, selecting the first supported type in
   * order of mp3, ogg and wav. the [path] should not include a file extension.
   * Settings [mp3], [ogg], or [wav] will cause the loader to skip that file type.
   * Once the audio is loaded, it will play it.
   */
  static AudioElement loadAndPlayAudio(String path, {bool mp3: true, bool ogg: true, bool wav: true}) {
    var elem = loadAudio(path, mp3: mp3, ogg: ogg, wav: wav);
    elem.onCanPlayThrough.first.then((evt) {
      elem.play();
    });
    return elem;
  }
}
