import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class AddUserControllers extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  var currentUser = Rxn<User>();

  @override
  void onInit() {
    super.onInit();
    currentUser.bindStream(_auth.authStateChanges());
  }

  // Registrar usuario con rol
   Future<bool> registerUser(String email, String password, String role) async {
    try {
      // Crear usuario en Firebase Authentication
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Guardar información adicional en Firestore
      await _db.collection('users').add({
        'email': email,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
      });

      Get.snackbar("Éxito", "Usuario registrado correctamente");
      return true; // ✅ Registro exitoso
    } catch (e) {
      Get.snackbar("Error", e.toString());
      return false; // ❌ Hubo un error
    }
  }

  // Iniciar sesión
  Future<void> loginUser(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      Get.snackbar("Éxito", "Inicio de sesión correcto");
    } on FirebaseAuthException catch (e) {
      Get.snackbar("Error", e.message ?? "Ocurrió un error");
    }
  }

  // Cerrar sesión
  Future<void> logoutUser() async {
    await _auth.signOut();
  }
}
