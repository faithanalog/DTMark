part of dtmark;

/**
 * Used for parsing wavefront object files (.obj) exported from programs
 * such as Blender
 */
class WavefrontParser {

  static List<WavefrontObject> parseFile(String contents) {
    //Normalize the text by replacing multiple spaces with one,
    //so that we can split on " " later
    var normalized = contents.replaceAll(new RegExp(r" +"), " ");
    
    //Array of lines for each object in the file
    //Split on lines beginning with 'o' to get object chunks
    //Split each of those chunks into lines
    var objLines = normalized.split(new RegExp(r"\no.*\n", multiLine: true))
                             .map((obj) => obj.split(new RegExp(r"\r?\n")));
    
    //Names of each seperate object. If it's empty, use a single list name of ""
    var objNames = new RegExp(r"o (.*)").allMatches(normalized)
                                         .map((m) => m.group(1));
    
    var toZip = objNames.isEmpty ? new IterableZip([objLines, [""]])
                                 : new IterableZip([objLines.skip(1), objNames]);
    return toZip.map((x) => parseObj(x[0], x[1])).toList();
  }
  
  static WavefrontObject parseObj(List<String> lines, String name) {
    var obj = new WavefrontObject();
    
    ofType(String prefix) => ((line) => line.startsWith(prefix));
    obj.name      = name;
    obj.positions = lines.where(ofType("v " )).map(_parseVec3).toList();
    obj.texCoords = lines.where(ofType("vt ")).map(_parseVec2).toList();
    obj.normals   = lines.where(ofType("vn ")).map(_parseVec3).toList();
    obj.faces     = lines.where(ofType("f " )).map(_parseFace).toList();
    
    return obj;
  }
  
  static Iterable<String> _args(String line) => line.split(" ").skip(1);
  
  static List<double> _argsNum(String line) => _args(line).map(double.parse).toList();
  
  static Vector3 _parseVec3(String line) => new Vector3.array(_argsNum(line));
  
  static Vector2 _parseVec2(String line) => new Vector2.array(_argsNum(line));
  
  static RegExp posNormPatt    = new RegExp(r"(.*)//(.*)");
  static RegExp posNormTexPatt = new RegExp(r"(.*)/(.*)/(.*)");
  static RegExp posTexPatt     = new RegExp(r"(.*)/(.*)");
  static RegExp posPatt        = new RegExp(r"(.*)");
  
  static _tryRegex(RegExp rgx, int normGroup, int texGroup) {
    return (String faceArg) {
      var match = rgx.firstMatch(faceArg);
      if (match == null)
        return null;
      var idx = new WavefrontIndex();
      idx.position = int.parse(match.group(1));
      idx.normal   = normGroup == -1 ? 0 : int.parse(match.group(normGroup));
      idx.texture  =  texGroup == -1 ? 0 : int.parse(match.group(texGroup));
      return idx;
    };
  }
  
  static List _faceTests = [
    _tryRegex(posNormPatt,     2, -1),
    _tryRegex(posNormTexPatt,  2,  3),
    _tryRegex(posTexPatt,     -1,  2),
    _tryRegex(posPatt,       - 1, -1)
  ];
  
  static WavefrontIndex _parseIndex(String faceArg) =>
    _faceTests.map((x) => x(faceArg)).firstWhere((x) => x != null);
  
  static WavefrontFace _parseFace(String line) =>
    new WavefrontFace(_args(line).map(_parseIndex).toList());

}

class WavefrontIndex {
  int position;
  int texture;
  int normal;
}

class WavefrontFace {
  List<WavefrontIndex> indices;
  WavefrontFace(this.indices);
}

class WavefrontObject {
  String name = "";
  List<Vector3> positions;
  List<Vector3> normals;
  List<Vector2> texCoords;
  List<WavefrontFace> faces;
}
