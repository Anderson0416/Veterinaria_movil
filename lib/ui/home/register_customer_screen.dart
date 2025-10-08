import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:veterinaria_movil/controllers/customer_controller.dart';
import 'package:veterinaria_movil/moldes/customer_model.dart';
import 'package:veterinaria_movil/ui/home/login_screens.dart';

class RegisterCustomerScreen extends StatelessWidget {
  const RegisterCustomerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Controladores de texto
    final nombreCtrl = TextEditingController();
    final apellidoCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final telCtrl = TextEditingController();
    final fechaCtrl = TextEditingController();
    final docNumCtrl = TextEditingController();
    final direccionCtrl = TextEditingController();

    String tipoDoc = "CC";
    String departamento = "Antioquia";
    String ciudad = "Medellín";

    final CustomerController customerController = Get.find();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Registro Cliente"),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionCard(
              title: "Datos personales",
              icon: Icons.person,
              children: [
                _input(nombreCtrl, "Nombre"),
                _input(apellidoCtrl, "Apellido"),
                _input(emailCtrl, "Correo electrónico", icon: Icons.email),
                _input(telCtrl, "Teléfono", icon: Icons.phone),
                _input(fechaCtrl, "Fecha de nacimiento (dd/mm/aaaa)",
                    icon: Icons.calendar_today),
              ],
            ),
            const SizedBox(height: 20),
            _sectionCard(
              title: "Documento de identidad",
              icon: Icons.credit_card,
              children: [
                DropdownButtonFormField<String>(
                  value: tipoDoc,
                  decoration: InputDecoration(
                    labelText: "Tipo de documento",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: "CC", child: Text("Cédula de ciudadanía")),
                    DropdownMenuItem(value: "TI", child: Text("Tarjeta de identidad")),
                    DropdownMenuItem(value: "CE", child: Text("Cédula de extranjería")),
                  ],
                  onChanged: (v) => tipoDoc = v ?? "CC",
                ),
                const SizedBox(height: 10),
                _input(docNumCtrl, "Número de documento"),
              ],
            ),
            const SizedBox(height: 20),
            _sectionCard(
              title: "Ubicación",
              icon: Icons.location_on,
              children: [
                DropdownButtonFormField<String>(
                  value: departamento,
                  decoration: InputDecoration(
                    labelText: "Departamento",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: "Antioquia", child: Text("Antioquia")),
                    DropdownMenuItem(value: "Cundinamarca", child: Text("Cundinamarca")),
                    DropdownMenuItem(value: "Valle del Cauca", child: Text("Valle del Cauca")),
                  ],
                  onChanged: (v) => departamento = v ?? "Antioquia",
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: ciudad,
                  decoration: InputDecoration(
                    labelText: "Ciudad",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: "Medellín", child: Text("Medellín")),
                    DropdownMenuItem(value: "Bogotá", child: Text("Bogotá")),
                    DropdownMenuItem(value: "Cali", child: Text("Cali")),
                  ],
                  onChanged: (v) => ciudad = v ?? "Medellín",
                ),
                const SizedBox(height: 10),
                _input(direccionCtrl, "Dirección", icon: Icons.home),
              ],
            ),
            const SizedBox(height: 30),

            // --- Botón registrar ---
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () async {
                  final nombre = nombreCtrl.text.trim();
                  final apellido = apellidoCtrl.text.trim();
                  final email = emailCtrl.text.trim();
                  final telefono = telCtrl.text.trim();
                  final fecha = fechaCtrl.text.trim();
                  final numeroDoc = docNumCtrl.text.trim();
                  final direccion = direccionCtrl.text.trim();

                  if (nombre.isEmpty ||
                      apellido.isEmpty ||
                      email.isEmpty ||
                      telefono.isEmpty ||
                      fecha.isEmpty ||
                      numeroDoc.isEmpty ||
                      direccion.isEmpty) {
                    Get.snackbar("Error", "Por favor completa todos los campos");
                    return;
                  }

                  // Crear modelo de cliente
                  final customer = Customer(
                    nombre: nombre,
                    apellido: apellido,
                    email: email,
                    telefono: telefono,
                    fechaNacimiento: fecha,
                    tipoDocumento: tipoDoc,
                    numeroDocumento: numeroDoc,
                    departamento: departamento,
                    ciudad: ciudad,
                    direccion: direccion,
                  );

                  // UID del usuario autenticado
                  final uid = FirebaseAuth.instance.currentUser?.uid;

                  // Guardar en Firestore
                  final docId =
                      await customerController.addCustomer(customer, docId: uid);

                  if (docId != null) {
                    Get.snackbar("Éxito", "Cliente registrado correctamente");
                    Get.offAll(() => const LoginScreens());
                  } else {
                    Get.snackbar("Error", "No se pudo registrar el cliente");
                  }
                },
                child: const Text(
                  "Registrar Cliente",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Widgets reutilizables ---

  Widget _input(TextEditingController controller, String label,
      {IconData icon = Icons.text_fields}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.green),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.green),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}
