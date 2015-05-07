part of dtmark;

class Camera {

  Vector3 pos = new Vector3.zero();
  double pitch = 0.0;
  double yaw = 0.0;

  void storeView(Matrix4 dest) {
    dest.setIdentity();
    dest.translate(-pos.x, -pos.y, -pos.z);
    dest.rotateY(-yaw);
    dest.rotateX(-pitch);
  }

}