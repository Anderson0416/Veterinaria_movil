class VeterinaryModel {
  String? id;
  String nombre;
  String direccion;
  String telefono;
  String nit;
  String correo;
  String? departamento;
  String? ciudad;
  String? horarioLV;
  String? horarioSab;

  VeterinaryModel({
    this.id,
    required this.nombre,
    required this.direccion,
    required this.telefono,
    required this.nit,
    required this.correo,
    this.departamento,
    this.ciudad,
    this.horarioLV,
    this.horarioSab,

  });

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'direccion': direccion,
      'telefono': telefono,
      'nit': nit,
      'correo': correo,
      'departamento': departamento,
      'ciudad': ciudad,
      'horarioLV': horarioLV,
      'horarioSab': horarioSab,
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
      departamento: map['departamento'],
      ciudad: map['ciudad'],
      horarioLV: map['horarioLV'],
      horarioSab: map['horarioSab'],
    );
  }
}
