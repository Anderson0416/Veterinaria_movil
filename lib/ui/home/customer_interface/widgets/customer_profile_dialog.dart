import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:veterinaria_movil/controllers/customer_controller.dart';
import 'package:veterinaria_movil/moldes/customer_model.dart';
import 'package:veterinaria_movil/ui/home/login_screens.dart';


class CustomerProfileDialog extends StatefulWidget {
  final Customer customer;

  const CustomerProfileDialog({super.key, required this.customer});

  @override
  State<CustomerProfileDialog> createState() => _CustomerProfileDialogState();
}

class _CustomerProfileDialogState extends State<CustomerProfileDialog> {
  final CustomerController controller = Get.put(CustomerController());
  late TextEditingController nombreCtrl;
  late TextEditingController apellidoCtrl;
  late TextEditingController emailCtrl;
  late TextEditingController telefonoCtrl;
  late TextEditingController fechaCtrl;
  late TextEditingController tipoDocCtrl;
  late TextEditingController numeroDocCtrl;
  late TextEditingController departamentoCtrl;
  late TextEditingController ciudadCtrl;
  late TextEditingController direccionCtrl;

  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    final c = widget.customer;
    nombreCtrl = TextEditingController(text: c.nombre);
    apellidoCtrl = TextEditingController(text: c.apellido);
    emailCtrl = TextEditingController(text: c.email);
    telefonoCtrl = TextEditingController(text: c.telefono);
    fechaCtrl = TextEditingController(text: c.fechaNacimiento);
    tipoDocCtrl = TextEditingController(text: c.tipoDocumento);
    numeroDocCtrl = TextEditingController(text: c.numeroDocumento);
    departamentoCtrl = TextEditingController(text: c.departamento);
    ciudadCtrl = TextEditingController(text: c.ciudad);
    direccionCtrl = TextEditingController(text: c.direccion);
  }

  @override
  void dispose() {
    nombreCtrl.dispose();
    apellidoCtrl.dispose();
    emailCtrl.dispose();
    telefonoCtrl.dispose();
    fechaCtrl.dispose();
    tipoDocCtrl.dispose();
    numeroDocCtrl.dispose();
    departamentoCtrl.dispose();
    ciudadCtrl.dispose();
    direccionCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardarCambios() async {
    setState(() => isSaving = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Get.snackbar("Error", "No hay sesión iniciada");
      return;
    }

    final updated = Customer(
      id: user.uid,
      nombre: nombreCtrl.text,
      apellido: apellidoCtrl.text,
      email: emailCtrl.text,
      telefono: telefonoCtrl.text,
      fechaNacimiento: fechaCtrl.text,
      tipoDocumento: tipoDocCtrl.text,
      numeroDocumento: numeroDocCtrl.text,
      departamento: departamentoCtrl.text,
      ciudad: ciudadCtrl.text,
      direccion: direccionCtrl.text,
    );

    final success = await controller.updateCustomer(user.uid, updated);
    setState(() => isSaving = false);

    if (success) {
      Get.back(); // cerrar el diálogo
      Get.snackbar("Éxito", "Datos actualizados correctamente");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.green.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person, color: Colors.green, size: 60),
            const SizedBox(height: 10),
            Text(
              "${nombreCtrl.text} ${apellidoCtrl.text}",
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                  fontSize: 18),
            ),
            const Divider(thickness: 1, color: Colors.green),
            const SizedBox(height: 10),

            // Campos editables
            _buildField("Nombre", nombreCtrl),
            _buildField("Apellido", apellidoCtrl),
            _buildField("Email", emailCtrl),
            _buildField("Teléfono", telefonoCtrl),
            _buildField("Fecha Nacimiento", fechaCtrl),
            _buildField("Tipo Documento", tipoDocCtrl),
            _buildField("Número Documento", numeroDocCtrl),
            _buildField("Departamento", departamentoCtrl),
            _buildField("Ciudad", ciudadCtrl),
            _buildField("Dirección", direccionCtrl),

            const SizedBox(height: 20),

            // Botones
            isSaving
                ? const CircularProgressIndicator(color: Colors.green)
                : Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _guardarCambios,
                          icon: const Icon(Icons.save),
                          label: const Text("Guardar Cambios"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            await FirebaseAuth.instance.signOut();
                            Get.offAll(() => const LoginScreens());
                          },
                          icon: const Icon(Icons.logout),
                          label: const Text("Cerrar Sesión"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Get.back(),
                        child: const Text("Cerrar",
                            style: TextStyle(color: Colors.green)),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl) {
  if (label == "Tipo Documento") {
    // Si es el campo tipoDocumento, usar dropdown
    return _buildDropdown(label, ctrl);
  }

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: TextField(
      controller: ctrl,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.green),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.green.shade400),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
  );
}

Widget _buildDropdown(String label, TextEditingController ctrl) {
  final List<String> opciones = ["CC", "TI", "CE"];
  String? valorSeleccionado = ctrl.text.isNotEmpty ? ctrl.text : null;

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: DropdownButtonFormField<String>(
      value: valorSeleccionado,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.green),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.green.shade400),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      items: opciones
          .map((op) => DropdownMenuItem(
                value: op,
                child: Text(op),
              ))
          .toList(),
      onChanged: (nuevoValor) {
        setState(() {
          ctrl.text = nuevoValor ?? "";
        });
      },
    ),
  );
}

}
