class RideOffer {
  final String id;
  final String passengerId;
  final String originAddress;
  final double originLat;
  final double originLng;
  final String destinationAddress;
  final double destinationLat;
  final double destinationLng;
  final double price;
  final double distance;

  RideOffer({
    required this.id,
    required this.passengerId,
    required this.originAddress,
    required this.originLat,
    required this.originLng,
    required this.destinationAddress,
    required this.destinationLat,
    required this.destinationLng,
    required this.price,
    required this.distance,
  });

  factory RideOffer.fromJson(Map<String, dynamic> json) {
    return RideOffer(
      id: json['id'],
      passengerId: json['passengerId'],
      originAddress: json['originAddress'],
      originLat: (json['originLat'] as num).toDouble(),
      originLng: (json['originLng'] as num).toDouble(),
      destinationAddress: json['destinationAddress'],
      destinationLat: (json['destinationLat'] as num).toDouble(),
      destinationLng: (json['destinationLng'] as num).toDouble(),
      price: (json['price'] as num).toDouble(),
      distance: (json['distance'] as num).toDouble(),
    );
  }
}
