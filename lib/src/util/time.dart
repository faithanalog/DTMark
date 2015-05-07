part of dtmark;


class Time {
  
  /**
   * Returns the current time in milliseconds since the epoch
   */
  static int get timeMillis => new DateTime.now().millisecondsSinceEpoch;
  
  /**
   * `[timeMillis] % [duration] / [duration]`
   * 
   * Useful for animations, among other things 
   */
  static double pctDone(int timeMillis, int duration) => (timeMillis % duration) / duration;

  static double lerp(double a, double b, double delta) => a + (b - a) * delta;
}
