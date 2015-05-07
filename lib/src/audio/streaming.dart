part of dtmark;

/**
 * Utilities for loading AudioElements, auto-selecting filetype based on browser capabilitites.
 */
class AudioStreaming {
  /**
   * Loads the audio element from path, attempting to select a supported type
   * based on the current browser. the [path] should not include a file extension.
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
   * Loads the audio element from path, attempting to select a supported type
   * based on the current browser. the [path] should not include a file extension.
   * If [typeOverride] is set, will load audio from [path].[typeOverride].
   * Once the audio is loaded, it will play it.
   */
  static AudioElement loadAndPlayAudio(String path, [String typeOverride = ""]) {
    var elem = loadAudio(path, typeOverride);
    elem.onCanPlayThrough.first.then((_) => elem.play());
    return elem;
  }
}
