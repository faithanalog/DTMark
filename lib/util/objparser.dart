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
        var args = line.split(" ");
        var type = args[0];
        if (type == "o") {
          if (!curObj.positions.isEmpty) {
            objects.add(curObj);
          }
          curObj = new WavefrontObject();
        } else if (type == "v") {
          curObj.positions.add(_parseVec3(args));
        } else if (type == "vt") {
          curObj.texCoords.add(_parseVec2(args));
        } else if (type == "vn") {
          curObj.normals.add(_parseVec3(args));
        } else if (type == "f") {
          curObj.faces.add(new WavefrontFace._parse(args));
        }
      }
    }
    if (!curObj.positions.isEmpty) {
      objects.add(curObj);
    }
  }

  Vector3 _parseVec3(List<String> args) {
    return new Vector3(double.parse(args[1]), double.parse(args[2]), double.parse(args[3]));
  }

  Vector2 _parseVec2(List<String> args) {
    return new Vector2(double.parse(args[1]), double.parse(args[2]));
  }
}

class WavefrontObject {
  String name = "";
  List<Vector3> positions = new List();
  List<Vector3> normals = new List();
  List<Vector2> texCoords = new List();
  List<WavefrontFace> faces = new List();
}

class WavefrontFace {
  Uint32List pos;
  Uint32List tex;
  Uint32List norm;

  bool hasTexture = false;
  bool hasNormal = false;
  bool quad = false;

  WavefrontFace._parse(List<String> args) {
    if (args.length >= 5) {
      quad = true;
    }

    pos = new Uint32List(args.length - 1);

    if (args[1].contains("//")) {
      hasNormal = true;
      norm = new Uint32List(pos.length);

    } else if (new RegExp(r"(.*)/(.*)/(.*)").hasMatch(args[1])) {
      hasNormal = true;
      hasTexture = true;
      norm = new Uint32List(pos.length);
      tex = new Uint32List(pos.length);
    } else if (new RegExp(r"(.*)/(.*)").hasMatch(args[1])) {
      hasTexture = true;
      tex = new Uint32List(pos.length);
    }

    for (int i = 0; i < pos.length; i++) {
      _parseVert(args[i + 1], i);
    }
  }

  void _parseVert(String vert, int index) {
    var args = vert.split(new RegExp("//?"));
    pos[index] = int.parse(args[0]);
    if (hasTexture) {
      tex[index] = int.parse(args[1]);
      if (hasNormal) {
        norm[index] = int.parse(args[2]);
      }
    } else {
      norm[index] = int.parse(args[1]);
    }
  }
}
