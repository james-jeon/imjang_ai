class CheckItem {
  final int noise;
  final int slope;
  final int commercial;
  final int parking;
  final int sunlight;

  CheckItem({
    required this.noise,
    required this.slope,
    required this.commercial,
    required this.parking,
    required this.sunlight,
  })  : assert(noise >= 1 && noise <= 5, 'noise must be 1-5'),
        assert(slope >= 1 && slope <= 5, 'slope must be 1-5'),
        assert(commercial >= 1 && commercial <= 5, 'commercial must be 1-5'),
        assert(parking >= 1 && parking <= 5, 'parking must be 1-5'),
        assert(sunlight >= 1 && sunlight <= 5, 'sunlight must be 1-5');

  double get average => (noise + slope + commercial + parking + sunlight) / 5.0;

  Map<String, int> toMap() => {
        'noise': noise,
        'slope': slope,
        'commercial': commercial,
        'parking': parking,
        'sunlight': sunlight,
      };

  factory CheckItem.fromMap(Map<String, dynamic> map) {
    return CheckItem(
      noise: (map['noise'] as num?)?.toInt() ?? 3,
      slope: (map['slope'] as num?)?.toInt() ?? 3,
      commercial: (map['commercial'] as num?)?.toInt() ?? 3,
      parking: (map['parking'] as num?)?.toInt() ?? 3,
      sunlight: (map['sunlight'] as num?)?.toInt() ?? 3,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CheckItem &&
          runtimeType == other.runtimeType &&
          noise == other.noise &&
          slope == other.slope &&
          commercial == other.commercial &&
          parking == other.parking &&
          sunlight == other.sunlight;

  @override
  int get hashCode =>
      noise.hashCode ^
      slope.hashCode ^
      commercial.hashCode ^
      parking.hashCode ^
      sunlight.hashCode;

  @override
  String toString() =>
      'CheckItem(noise: $noise, slope: $slope, commercial: $commercial, parking: $parking, sunlight: $sunlight)';
}
