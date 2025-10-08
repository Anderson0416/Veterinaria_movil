import 'package:veterinaria_movil/moldes/rol_moldes.dart';

class User{
  int? id;
  String userName;
  String password;
  String email;
  Rol rol;

  User({this.id, required this.userName, required this.password, required this.email, required this.rol});
}