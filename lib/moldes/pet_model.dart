class PetModel {
  String? id;
  String nombre;
  String raza;
  String edad;
  String tipo;
  String duenoId; // 🔗 Relación con el dueño (cliente logueado)

  PetModel({
    this.id,
    required this.nombre,
    required this.raza,
    required this.edad,
    required this.tipo,
    required this.duenoId,
  });

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'raza': raza,
      'edad': edad,
      'tipo': tipo,
      'duenoId': duenoId,
    };
  }

  factory PetModel.fromMap(Map<String, dynamic> map, String id) {
    return PetModel(
      id: id,
      nombre: map['nombre'] ?? '',
      raza: map['raza'] ?? '',
      edad: map['edad'] ?? '',
      tipo: map['tipo'] ?? '',
      duenoId: map['duenoId'] ?? '',
    );
  }
}
