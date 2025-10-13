// lib/moldes/customer_model.dart
class Customer {
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

  Customer({
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
  });

  Map<String, dynamic> toMap() {
    return {
      "nombre": nombre,
      "apellido": apellido,
      "email": email,
      "telefono": telefono,
      "fechaNacimiento": fechaNacimiento,
      "tipoDocumento": tipoDocumento,
      "numeroDocumento": numeroDocumento,
      "departamento": departamento,
      "ciudad": ciudad,
      "direccion": direccion,
      "createdAt": DateTime.now().toUtc(),
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map, {String? id}) {
    return Customer(
      id: id,
      nombre: map["nombre"] ?? "",
      apellido: map["apellido"] ?? "",
      email: map["email"] ?? "",
      telefono: map["telefono"] ?? "",
      fechaNacimiento: map["fechaNacimiento"] ?? "",
      tipoDocumento: map["tipoDocumento"] ?? "",
      numeroDocumento: map["numeroDocumento"] ?? "",
      departamento: map["departamento"] ?? "",
      ciudad: map["ciudad"] ?? "",
      direccion: map["direccion"] ?? "",
    );
  }
}
