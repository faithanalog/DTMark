part of dtmark;

/**
 * Used for pasring wavefront object files (.obj) exported from programs
 * such as Blender
 */
class WavefrontParser {

  List<Vector3> positions;
  List<Vector3> normals;
  List<Vector2> texCoords;
  List<int> indices;

  parseObject(String contents) {
    var lines = contents.split(new RegExp(r"(\r?\n)+"));
    for (var line in lines) {
      if (line.startsWith("#")) {
        continue; //Comment line
      } else if (line.startsWith("vt")) {

      } else if (line.startsWith("vn")) {

      } else if (line.startsWith("v")) {

      }
    }
  }

}
