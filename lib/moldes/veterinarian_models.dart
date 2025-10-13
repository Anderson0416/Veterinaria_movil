class VeterinarianModel {
  String? id;
  String nombre;
  String apellido;
  String email;
  String telefono;
  String fechaNacimiento;
  String tipoDocumento;
  String numeroDocumento;
  String departamento;
  String ciudad;
  String direccion;
  String especialidad; // 🆕 Campo agregado
  String veterinaryId; // 🔗 ID de la veterinaria asociada

  VeterinarianModel({
    this.id,
    required this.nombre,
    required this.apellido,
    required this.email,
    required this.telefono,
    required this.fechaNacimiento,
    required this.tipoDocumento,
    required this.numeroDocumento,
    required this.departamento,
    required this.ciudad,
    required this.direccion,
    required this.especialidad, // 🆕
    required this.veterinaryId,
  });

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'apellido': apellido,
      'email': email,
      'telefono': telefono,
      'fechaNacimiento': fechaNacimiento,
      'tipoDocumento': tipoDocumento,
      'numeroDocumento': numeroDocumento,
      'departamento': departamento,
      'ciudad': ciudad,
      'direccion': direccion,
      'especialidad': especialidad, // 🆕
      'veterinaryId': veterinaryId,
    };
  }

  factory VeterinarianModel.fromMap(Map<String, dynamic> map, String id) {
    return VeterinarianModel(
      id: id,
      nombre: map['nombre'] ?? '',
      apellido: map['apellido'] ?? '',
      email: map['email'] ?? '',
      telefono: map['telefono'] ?? '',
      fechaNacimiento: map['fechaNacimiento'] ?? '',
      tipoDocumento: map['tipoDocumento'] ?? '',
      numeroDocumento: map['numeroDocumento'] ?? '',
      departamento: map['departamento'] ?? '',
      ciudad: map['ciudad'] ?? '',
      direccion: map['direccion'] ?? '',
      especialidad: map['especialidad'] ?? '', // 🆕
      veterinaryId: map['veterinaryId'] ?? '',
    );
  }
}
