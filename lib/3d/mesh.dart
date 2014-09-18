part of dtmark;

class Mesh {

  Material material;
  Geometry geometry;

  Vector3 position = new Vector3.zero();
  Vector3 rotation = new Vector3.zero();

  List<Mesh> children = new List();

  Mesh(this.material, this.geometry);

}
