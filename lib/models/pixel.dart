class Pixel {
  final double lat;
  final double lon;
  final int x;
  final int y;
  final int? userId;

  Pixel({required this.lat, required this.lon, required this.x, required this.y, required this.userId});

  factory Pixel.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {
      'lat': var lat,
      'lon': var lon,
      'x': var x,
      'y': var y,
      'userId': var userId,
      } =>
          Pixel(
            lat: lat,
            lon: lon,
            x: x,
            y: y,
            userId: userId,
          ),
      _ => throw const FormatException('Failed to load Pixel.'),
    };
  }

  static List<Pixel> listFromJson(List<dynamic> json) {
    return [
      for (var element in json)
        Pixel.fromJson(element)
    ];
  }
}