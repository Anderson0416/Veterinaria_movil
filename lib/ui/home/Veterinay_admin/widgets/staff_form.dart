import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../../../controllers/veterinarian_controller.dart';
import '../../../../controllers/add_user_controllers.dart';
import '../../../../moldes/veterinarian_models.dart';

class StaffForm extends StatefulWidget {
  const StaffForm({super.key});

  @override
  State<StaffForm> createState() => _StaffFormState();
}

class _StaffFormState extends State<StaffForm> {
  final _vetController = Get.find<VeterinarianController>();
  final _userController = Get.put(AddUserControllers());

  // Controladores de texto
  final nombreCtrl = TextEditingController();
  final apellidoCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  final telefonoCtrl = TextEditingController();
  final fechaNacimientoCtrl = TextEditingController();
  final tipoDocumentoCtrl = TextEditingController();
  final numeroDocumentoCtrl = TextEditingController();
  final departamentoCtrl = TextEditingController();
  final ciudadCtrl = TextEditingController();
  final direccionCtrl = TextEditingController();
  String? especialidadSeleccionada;

  final List<String> especialidades = [
    "Veterinario General",
    "Especialista en Imagenología Animal",
    "Cirujano Veterinario",
    "Dermatólogo Animal",
  ];

  bool isLoading = false;

  // 🧩 Registrar veterinario sin cerrar sesión actual
  Future<void> _registrarVeterinario() async {
    if (nombreCtrl.text.isEmpty ||
        apellidoCtrl.text.isEmpty ||
        emailCtrl.text.isEmpty ||
        passwordCtrl.text.isEmpty ||
        telefonoCtrl.text.isEmpty ||
        especialidadSeleccionada == null) {
      Get.snackbar("Error", "Por favor completa todos los campos obligatorios");
      return;
    }

    setState(() => isLoading = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        Get.snackbar("Error", "No hay veterinaria logueada");
        return;
      }

      // ✅ Crea una app secundaria temporal para registrar al nuevo usuario
      final FirebaseApp secondaryApp = await Firebase.initializeApp(
        name: 'SecondaryApp',
        options: Firebase.app().options,
      );

      final FirebaseAuth secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

      // 🔹 Crear el nuevo usuario con la instancia secundaria
      final newUserCredential = await secondaryAuth.createUserWithEmailAndPassword(
        email: emailCtrl.text.trim(),
        password: passwordCtrl.text.trim(),
      );

      final newUser = newUserCredential.user;
      if (newUser == null) throw Exception("No se pudo crear el usuario");

      // 🔹 Guardar en colección users
      await FirebaseFirestore.instance.collection('users').doc(newUser.uid).set({
        'email': emailCtrl.text.trim(),
        'role': 'veterinario',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 🔹 Registrar datos del veterinario
      final nuevoVet = VeterinarianModel(
        nombre: nombreCtrl.text.trim(),
        apellido: apellidoCtrl.text.trim(),
        email: emailCtrl.text.trim(),
        telefono: telefonoCtrl.text.trim(),
        fechaNacimiento: fechaNacimientoCtrl.text.trim(),
        tipoDocumento: tipoDocumentoCtrl.text.trim(),
        numeroDocumento: numeroDocumentoCtrl.text.trim(),
        departamento: departamentoCtrl.text.trim(),
        ciudad: ciudadCtrl.text.trim(),
        direccion: direccionCtrl.text.trim(),
        especialidad: especialidadSeleccionada!,
        veterinaryId: currentUser.uid,
      );

      await _vetController.addVeterinarian(nuevoVet);

      // 🔹 Cerrar sesión secundaria (NO afecta la actual)
      await secondaryAuth.signOut();
      await secondaryApp.delete();

      _limpiarCampos();
      Get.snackbar("Éxito", "Veterinario registrado correctamente ✅");
    } on FirebaseAuthException catch (e) {
      Get.snackbar("Error", e.message ?? "Error al registrar veterinario");
    } catch (e) {
      Get.snackbar("Error", "No se pudo registrar el veterinario: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _limpiarCampos() {
    nombreCtrl.clear();
    apellidoCtrl.clear();
    emailCtrl.clear();
    passwordCtrl.clear();
    telefonoCtrl.clear();
    fechaNacimientoCtrl.clear();
    tipoDocumentoCtrl.clear();
    numeroDocumentoCtrl.clear();
    departamentoCtrl.clear();
    ciudadCtrl.clear();
    direccionCtrl.clear();
    setState(() => especialidadSeleccionada = null);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              "Registrar Nuevo Veterinario",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),

            _buildTextField("Nombre", nombreCtrl),
            _buildTextField("Apellido", apellidoCtrl),
            _buildDropdown("Especialidad", especialidades, especialidadSeleccionada,
                (v) => setState(() => especialidadSeleccionada = v)),
            _buildTextField("Email", emailCtrl),
            _buildTextField("Contraseña", passwordCtrl, isPassword: true),
            _buildTextField("Teléfono", telefonoCtrl),

            // 🔹 Fecha de nacimiento (como antes)
            _buildTextField("Fecha de Nacimiento", fechaNacimientoCtrl),

            _buildTextField("Tipo de Documento", tipoDocumentoCtrl),
            _buildTextField("Número de Documento", numeroDocumentoCtrl),
            _buildTextField("Departamento", departamentoCtrl),
            _buildTextField("Ciudad", ciudadCtrl),
            _buildTextField("Dirección", direccionCtrl),

            const SizedBox(height: 16),
            isLoading
                ? const CircularProgressIndicator(color: Colors.green)
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _registrarVeterinario,
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: const Text(
                        "Registrar Veterinario",
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController ctrl, {bool isPassword = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: ctrl,
        obscureText: isPassword,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.green),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.green.shade400),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> items, String? value,
      void Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.green),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.green.shade400),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            hint: const Text("Seleccionar especialidad"),
            items: items
                .map((item) => DropdownMenuItem(
                      value: item,
                      child: Text(item),
                    ))
                .toList(),
            onChanged: onChanged,
            isExpanded: true,
          ),
        ),
      ),
    );
  }
}
