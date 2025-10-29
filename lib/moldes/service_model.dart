class ServiceModel {
  String? id;
  String nombre;
  String descripcion;
  double precio;
  String veterinaryId;

  ServiceModel({
    this.id,
    required this.nombre,
    required this.descripcion,
    required this.precio,
    required this.veterinaryId,
  });

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'descripcion': descripcion,
      'precio': precio,
      'veterinaryId': veterinaryId,
    };
  }

  factory ServiceModel.fromMap(Map<String, dynamic> map, String id) {
    return ServiceModel(
      id: id,
      nombre: map['nombre'] ?? '',
      descripcion: map['descripcion'] ?? '',
      precio: (map['precio'] ?? 0).toDouble(),
      veterinaryId: map['veterinaryId'] ?? '',
    );
  }
}
