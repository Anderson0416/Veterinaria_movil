import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../moldes/customer_model.dart';

class StaffForm extends StatefulWidget {
  const StaffForm({super.key});

  @override
  State<StaffForm> createState() => _StaffFormState();
}

class _StaffFormState extends State<StaffForm> {
  final nombreCtrl = TextEditingController();
  final apellidoCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final telefonoCtrl = TextEditingController();
  final contrasenaCtrl = TextEditingController();
  String? rolSeleccionado;

  final List<String> roles = [
    "Veterinario Doctor",
    "Especialista en Imagen y Cuidado Animal",
  ];

  bool isLoading = false;

  Future<void> _registrarPersonal() async {
    if (nombreCtrl.text.isEmpty ||
        apellidoCtrl.text.isEmpty ||
        emailCtrl.text.isEmpty ||
        telefonoCtrl.text.isEmpty ||
        contrasenaCtrl.text.isEmpty ||
        rolSeleccionado == null) {
      Get.snackbar("Error", "Por favor completa todos los campos");
      return;
    }

    setState(() => isLoading = true);

    try {
      final nuevo = Customer(
        nombre: nombreCtrl.text.trim(),
        apellido: apellidoCtrl.text.trim(),
        email: emailCtrl.text.trim(),
        telefono: telefonoCtrl.text.trim(),
        fechaNacimiento: "",
        tipoDocumento: "",
        numeroDocumento: "",
        departamento: "",
        ciudad: "",
        direccion: "",
      );

      final data = nuevo.toMap();
      data["rol"] = rolSeleccionado;
      data["contrasenaTemporal"] = contrasenaCtrl.text.trim();

      await FirebaseFirestore.instance.collection("personal").add(data);

      Get.snackbar("Éxito", "Personal registrado correctamente");
      _limpiar();
    } catch (e) {
      Get.snackbar("Error", "No se pudo registrar: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _limpiar() {
    nombreCtrl.clear();
    apellidoCtrl.clear();
    emailCtrl.clear();
    telefonoCtrl.clear();
    contrasenaCtrl.clear();
    setState(() => rolSeleccionado = null);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              "Agregar Nuevo Personal",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 16),

            _buildTextField("Nombre", nombreCtrl),
            _buildTextField("Apellido", apellidoCtrl),
            _buildDropdown("Rol", roles, rolSeleccionado, (v) {
              setState(() => rolSeleccionado = v);
            }),
            _buildTextField("Email", emailCtrl),
            _buildTextField("Teléfono", telefonoCtrl),
            _buildTextField("Contraseña Temporal", contrasenaCtrl, oculto: true),

            const SizedBox(height: 16),

            isLoading
                ? const CircularProgressIndicator(color: Colors.green)
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _registrarPersonal,
                      icon: const Icon(Icons.save, color: Colors.white),
                      label: const Text(
                        "Registrar Personal",
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

  Widget _buildTextField(String label, TextEditingController ctrl,
      {bool oculto = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: ctrl,
        obscureText: oculto,
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
            hint: const Text("Seleccionar rol"),
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
