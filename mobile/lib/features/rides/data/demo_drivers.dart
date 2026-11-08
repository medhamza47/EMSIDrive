class DemoDriver {
  const DemoDriver(
    this.id,
    this.name,
    this.major,
    this.distance,
    this.time,
    this.rating,
    this.isMotorcycle,
    this.fare,
    this.tripCount,
  );

  final String id;
  final String name;
  final String major;
  final double distance;
  final String time;
  final double rating;
  final bool isMotorcycle;
  final int fare;
  final int tripCount;

  static const all = [
    DemoDriver('salma', 'Salma B.', '2DSI', 0.4, '08:15', 4.8, true, 8, 42),
    DemoDriver('omar', 'Omar K.', 'GI', 0.9, '08:00', 4.5, false, 10, 29),
    DemoDriver('imane', 'Imane R.', '2DSI', 1.3, '08:20', 4.9, false, 10, 36),
    DemoDriver('anas', 'Anas T.', 'ISI', 2.1, '08:10', 4.3, true, 8, 18),
  ];

  static DemoDriver find(String? id) =>
      all.firstWhere((driver) => driver.id == id, orElse: () => all.first);
}
