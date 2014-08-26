part of dtmark;

class FontRenderer {

  double scale = 1.0;
  int size = 0;

  Float32List charWidths = new Float32List(256);
  Float32List charHeights = new Float32List(256);
  Float32List charU0 = new Float32List(256);
  Float32List charU1 = new Float32List(256);
  Float32List charV0 = new Float32List(256);
  Float32List charV1 = new Float32List(256);

  double xSpacing = 0.0;

  Texture _tex;

  FontRenderer(String url, WebGL.RenderingContext gl) {
    HttpRequest.getString(url).then((text) {
      var fontInfo = JSON.decode(text);
      _tex = new Texture.load(fontInfo["textureUrl"], gl);
      List chars = fontInfo["chars"];
      size = fontInfo["size"];
      xSpacing = fontInfo["xSpacing"];
      for (final obj in chars) {
        int code = obj["charCode"];
        charWidths[code] = obj["width"];
        charHeights[code] = obj["height"];
        charU0[code] = obj["u0"];
        charV0[code] = obj["v0"];
        charU1[code] = obj["u1"];
        charV1[code] = obj["v1"];
      }
    });
  }

  /**
   * Creates a monospace font renderer from an existing texture [tex].
   * [charWidth] and [charHeight] define the dimensions of the actual
   * text characters, while [cellWidth] and [cellHeight] define the
   * dimensions of each cell. See FontRenderer.lowResMono src for example.
   * Size is set to charHeight unless [size] is defined. [xSpacing]
   * defaults to 1
   */
  FontRenderer.mono(Texture tex, WebGL.RenderingContext gl, int charWidth,
      int charHeight, int cellWidth, int cellHeight, {int xSpacing: 1, int size: -1}) {

    this.size = size == -1 ? charHeight : size;
    this.xSpacing = xSpacing.toDouble();
    for (var i = 0; i < 256; i++) {
      charWidths[i] = charWidth.toDouble();
      charHeights[i] = charHeight.toDouble();
    }

    tex.onLoad.then((evt) {
      double cwidth = charWidth / tex.width;
      double cheight = charHeight / tex.height;

      //U/V width/heights of each character cell
      double texWidth = cellWidth / tex.width;
      double texHeight = cellHeight / tex.height;

      for (var i = 0; i < 256; i++) {
        charU0[i] = (i & 15) * texWidth;
        charV0[i] = (i >> 4) * texHeight;
        charU1[i] = charU0[i] + cwidth;
        charV1[i] = charV0[i] + cheight;
      }
    });
    _tex = tex;
  }

  /**
   * Creates a 6 wide by 8 tall monospace font from an embedded image
   */
  factory FontRenderer.lowResMono(WebGL.RenderingContext gl) {
    //Image data, see res/font_bmp.png. Dimensions are 96x128
    const String base64img =
      '''
data:image/png;base64,
iVBORw0KGgoAAAANSUhEUgAAAGAAAACACAYAAAD03Gy6AAAE5ElEQVR42u2c25LbIBBEkYv//2Xl
JXKp8NwBrzY5vQ+OWVagaRimB8hxnufZjna0G452tLOdbQTl68tfrbUm/hZ8Ba/3vyDhhwmAhAcQ
MKwF4JsEYPwfJADjg/8VB/H4E3QAeEgUBCAAAgAEQAAA6ICr/Gzv/YJ3+VX299Mtl55znueowj+e
E+3PBa0/2ef8czrgat3Ktt7raD322hhTKtJzst8326RvM/IwG0T6LePNGn8k4fr9nZTZdhf0t0bA
/WWkF9VeePwbyQgWadLfV19e+hwHk9WW5lOSg2X/DLBGu2RozUDLVj3BTd0/tT5JA27BTH2lOxyd
FaPRrx/pRa/fWa7Da1vz3REXuMoG4/sG+vEKj+wVoy4ygi5jZhdjbcHNGk+qv2IWsufyZB0wLJIh
HTDWv+L6+8OP41DjdK/+ze+69bX+W+9Vid8lfSPV1/SH0J/+Mb1G3+xNx+u7F1ZmogYtprd0g7aI
W+8VWWwrbshr//a9m0aSqPY64UU2WntWFLLDJ8/qDG9ASeG4gO4aqao+PYNaeqCiG6QFX3uXjMaY
iaK0SO5DiFVGVEZ9jiLHa6uiG6TvY7nnarR4v+pSA/3t5Tg30ljWmN90IRk9IZFQdZNDWTdTBdJC
JyXWrkXYch3ey0ZTF9HnWCM9s/hXhKFV76fyT6CiAyLxfrW+Ftdn4/3xfsPZTlcfDDP43a70HO3+
RLS+059eiqNX1J+NRqKLueWLtd9lXU0kclT6v+9+wG4/t+v5s4IraUtbiFkZxhWG8BZPK1Qcxdu3
jV+deSYBVrRgGava6cqmiyfWZsio7D94UZODffcDnnrbxutXZT96wk32cr4nE79HR6s38isb9dLC
7205Wkq+Oliz+gZ8SwesiuvH+l5cn42jV5ZndIaX97d0RuDcUV8W13u5j6dIcC9kjOa4rCgscaDg
958NnTnnkxFzlWcG/raX4voVSbSVsbqWrbRG4grBFZlhoRlw3H4iYZuWSrg/pxrKVUa0lhJYYfwd
4WnKBWkvsalDUzMi0qdZ4bj4nXuoMY+EipawXFbFpcyIscgewqzqrh5lBLt1gHeOfhy0s/+/0D0/
btUfzwVV+7PiPsEwK9bfD3iKPx/9tHRq+f4zm4/JnnvdgG42EkkLZ3I+kdRyVMhpqfOoP/d8vbfO
aOvjuCY69ulh5q2TzdHdJet4ytjxzEKr9c07G5Q9UW1FiFn7iCfjoqnbVWFc9AhIxJg7hd5suqMU
hnpTfkdeJlO/2h/PwNkwd5KsHh6t1VRENDSopkAi9VftB6wUcWiAJ+mABfFs6bz87nar5X+/fNxX
iN5zTusAIGsQz6Volk2sTy9T3NzLpE+tvhTpRC9If6O8IuiyBEYup7cW3BGzLr9FdsR27oZlk3SB
Wyvl9qXgw3leD0c12kt8e0MmGjp66ZXoxs5MWBs+mLUq9RoZTd5RvspOllbfuqDxkDBw/U15bZaM
sbe03xAZ0Zbst1ynd7/B6quXCwLoAMrRAb8TEAABEAAgAAIAQAcQp6MDWAMABEAAgAAIAAAdQDk6
gDUAQAAEAAiAAADQAZSjA1gDAARAAIAACAAAHUA5OoA1AEAABAAIgAAA0AGUowNYAwAEQACAAAgA
AB1AOTqANQBAAAQACIAAANABlKMDWAMABEAAgAAIAOAZ+AOg2b+6t+iJHQAAAABJRU5ErkJggg==
      ''';
    var src = base64img.replaceAll("\n", "");
    var tex = new Texture.load(src, gl);
    return new FontRenderer.mono(tex, gl, 5, 7, 6, 8);
  }

  FontRenderer.generate(String font, this.size, WebGL.RenderingContext gl) {
    var canvas = new CanvasElement();
    CanvasRenderingContext2D ctx = canvas.getContext("2d");
    ctx.font = "$size\px $font";
    List<int> points = new List.generate(128, (i) => i, growable: false);
    String chars = UTF8.decode(points, allowMalformed: true);
    double maxWidth = 0.0;
    double charHeight = (size.toDouble() + (size / 8)).ceilToDouble();
    for (int i = 0; i < 128; i++) {
      var char = chars.substring(i, i + 1);
      var metrics = ctx.measureText(char);
      charWidths[i] = metrics.width;
      charHeights[i] = charHeight;
      maxWidth = Math.max(maxWidth, metrics.width);
    }

    maxWidth += 2.0;
    charHeight += 2.0;

    int width = nextPowerOf2((maxWidth * 16).toInt());
    int height = nextPowerOf2((charHeight * 8).toInt());

    double oneOverW = 1 / width;
    double oneOverH = 1 / height;

    double cellOffX = width / 16;
    double cellOffY = height / 8;

    canvas.width = width;
    canvas.height = height;

    ctx.font = "$size\px $font";
    ctx.fillStyle = "#FFFFFF";
    ctx.textBaseline = "top";
    ctx.translate(1, 1);
    for (int i = 0; i < 128; i++) {
      var char = chars.substring(i, i + 1);
      charU0[i] = (i & 15) / 16.0 + oneOverW;
      charV0[i] = (i >> 4) / 8.0 + oneOverH;
      charU1[i] = charU0[i] + charWidths[i] * oneOverW;
      charV1[i] = charV0[i] + charHeights[i] * oneOverH;

      ctx.fillText(char, (i & 15) * cellOffX, (i >> 4) * cellOffY);
    }

    dispInfo(String char) {
      int cc = char.codeUnitAt(0);
      print("==$cc==");
      print("${charU0[cc]} ${charU1[cc]}");
      print("${charV0[cc]} ${charV1[cc]}");
      print("${charWidths[cc]} ${charHeights[cc]}");
    }

    _tex = new Texture(canvas, gl, minFilter: WebGL.LINEAR_MIPMAP_LINEAR, magFilter: WebGL.LINEAR, mipmap: true);
  }

  double getWidth(String str) {
    double w = 0.0;
    for (final code in str.codeUnits) {
      w += charWidths[code];
    }
    return (w + xSpacing * str.length) * scale;
  }

  double getHeight() {
    return size * scale;
  }

  void drawString(SpriteBatch batch, String str, double x, double y) {
    for (final code in str.codeUnits) {
      if (code >= 256) {
        continue;
      }
      _drawChar(batch, code, x, y);
      x += (charWidths[code] + xSpacing) * scale;
    }
  }

  void drawStringCentered(SpriteBatch batch, String str, double x, double y) {
    int w = (getWidth(str) * 0.5).floor();
    drawString(batch, str, x - w, y);
  }

  void _drawChar(SpriteBatch batch, int code, double x, double y) {
    batch.drawTexRegionUV(_tex, x, y, charWidths[code] * scale, charHeights[code] * scale, charU0[code], charV0[code], charU1[code], charV1[code]);
  }

}
