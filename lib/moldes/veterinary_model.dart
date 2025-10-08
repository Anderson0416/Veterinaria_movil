class VeterinaryModel {
  String? id;
  String nombre;
  String direccion;
  String telefono;
  String nit;
  String correo;

  VeterinaryModel({
    this.id,
    required this.nombre,
    required this.direccion,
    required this.telefono,
    required this.nit,
    required this.correo,
  });

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'direccion': direccion,
      'telefono': telefono,
      'nit': nit,
      'correo': correo,
    };
  }

  factory VeterinaryModel.fromMap(Map<String, dynamic> map, String id) {
    return VeterinaryModel(
      id: id,
      nombre: map['nombre'] ?? '',
      direccion: map['direccion'] ?? '',
      telefono: map['telefono'] ?? '',
      nit: map['nit'] ?? '',
      correo: map['correo'] ?? '',
    );
  }
}
