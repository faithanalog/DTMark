part of dtmark;

class AudioStreaming {
  /**
   * Loads the audio element from path, selecting the first supported type in
   * order of mp3, ogg and wav. the [path] should not include a file extension.
   * Settings [mp3], [ogg], or [wav] will cause the loader to skip that file type.
   */
  static AudioElement loadAudio(String path, {bool mp3: true, bool ogg: true, bool wav: true}) {
    var elem = new AudioElement();
    var toTry = new List<String>();
    if (mp3 && elem.canPlayType("audio/mp3") != "") {
      toTry.add("mp3");
    }
    if (ogg && elem.canPlayType("audio/ogg") != "") {
      toTry.add("ogg");
    }
    if (wav && elem.canPlayType("audio/wav") != "") {
      toTry.add("wav");
    }
    for (final type in toTry) {
      var srcElem = new SourceElement();
      srcElem.src = "$path.$type";
      srcElem.type = "audio/$type";
      elem.append(srcElem);
    }
    elem.load();
    return elem;
  }
  
  /**
   * Loads the audio element from path, selecting the first supported type in
   * order of mp3, ogg and wav. the [path] should not include a file extension.
   * Settings [mp3], [ogg], or [wav] will cause the loader to skip that file type.
   * Once the audio is loaded, it will play it.
   */
  static  AudioElement loadAndPlayAudio(String path, {bool mp3: true, bool ogg: true, bool wav: true}) {
    var elem = loadAudio(path, mp3: mp3, ogg: ogg, wav: wav);
    elem.onLoadStart.first.then((evt) {
      elem.play();
    });
    return elem;
  }
}