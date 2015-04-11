part of dtmark;

/**
 * Used for parsing wavefront object files (.obj) exported from programs
 * such as Blender
 */
class WavefrontParser {

  List<WavefrontObject> objects;

  void parseFile(String contents) {

    WavefrontObject curObj = new WavefrontObject();

    var lines = contents.split(new RegExp(r"(\r?\n)+"));
    for (var line in lines) {
      if (line.startsWith("#")) {
        continue; //Comment line
      } else {
        var split = line.split(" ");
        var type = split.first;
        var args = split.skip(1);
        switch (type) {
        case "o":
          if (!curObj.positions.isEmpty) {
            objects.add(curObj);
          }
          curObj = new WavefrontObject();
          break;
        case "v":
          curObj.positions.add(_parseVec3(args));
          break;
        case "vt":
          curObj.texCoords.add(_parseVec2(args));
          break;
        case "vn":
          curObj.normals.add(_parseVec3(args));
          break;
        case "f":
          curObj.faces.add(new WavefrontFace._parse(args));
          break;
        }
      }
    }
    if (!curObj.positions.isEmpty)
      objects.add(curObj);
  }

  Vector3 _parseVec3(Iterable<String> args) => new Vector3.array(args.map(double.parse).toList());

  Vector2 _parseVec2(Iterable<String> args) => new Vector2.array(args.map(double.parse).toList());

}

class WavefrontObject {
  String name = "";
  List<Vector3> positions   = new List();
  List<Vector3> normals     = new List();
  List<Vector2> texCoords   = new List();
  List<WavefrontFace> faces = new List();
}

class WavefrontFace {
  Uint32List pos;
  Uint32List tex;
  Uint32List norm;

  bool hasTexture = false;
  bool hasNormal = false;
  bool quad = false;

  WavefrontFace._parse(Iterable<String> args) {
    quad = args.length >= 4;

    pos = new Uint32List(args.length);

    if (args.first.contains("//")) {
      hasNormal = true;
      norm = new Uint32List(pos.length);
    } else if (new RegExp(r"(.*)/(.*)/(.*)").hasMatch(args.first)) {
      hasNormal = true;
      hasTexture = true;
      norm = new Uint32List(pos.length);
      tex = new Uint32List(pos.length);
    } else if (new RegExp(r"(.*)/(.*)").hasMatch(args.first)) {
      hasTexture = true;
      tex = new Uint32List(pos.length);
    }

    int i = 0;
    for (final vert in args) {
      _parseVert(vert, i);
      i++;
    }
  }

  void _parseVert(String vert, int index) {
    var args = vert.split(new RegExp(r"//?")).map(int.parse);
    pos[index] = args[0];
    if (hasTexture)
      tex[index] = args[1];
    if (hasNormal)
      norm[index] = args[hasTexture ? 2 : 1];
  }
}
