import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../controllers/veterinary_controller.dart';
import '../../../../moldes/veterinary_model.dart';

class VeterinaryDataScreen extends StatefulWidget {
  const VeterinaryDataScreen({super.key});

  @override
  State<VeterinaryDataScreen> createState() => _VeterinaryDataScreenState();
}

class _VeterinaryDataScreenState extends State<VeterinaryDataScreen> {
  final VeterinaryController controller = Get.put(VeterinaryController());
  final user = FirebaseAuth.instance.currentUser;

  // Controladores de texto
  final nombreCtrl = TextEditingController();
  final nitCtrl = TextEditingController();
  final telefonoCtrl = TextEditingController();
  final correoCtrl = TextEditingController();
  final direccionCtrl = TextEditingController();
  final horarioLVctrl = TextEditingController();
  final horarioSabCtrl = TextEditingController();

  // Dropdowns
  String? departamentoSeleccionado;
  String? ciudadSeleccionada;

  final List<String> departamentos = [
    "Cundinamarca",
    "Antioquia",
    "Santander",
    "Valle del Cauca",
    "Atlántico",
    "Cesar",
  ];

  final Map<String, List<String>> ciudadesPorDepartamento = {
    "Cundinamarca": ["Bogotá", "Soacha", "Fusagasugá"],
    "Antioquia": ["Medellín", "Envigado", "Bello"],
    "Santander": ["Bucaramanga", "Floridablanca"],
    "Valle del Cauca": ["Cali", "Palmira", "Buenaventura"],
    "Atlántico": ["Barranquilla", "Soledad"],
    "Cesar": ["Valledupar", "Bosconia", "Aguachica"],
  };

  @override
  void initState() {
    super.initState();
    _loadVeterinaryData();
  }

  Future<void> _loadVeterinaryData() async {
    if (user == null) return;
    final data = await controller.getVeterinaryById(user!.uid);
    if (data != null) {
      setState(() {
        nombreCtrl.text = data.nombre;
        nitCtrl.text = data.nit;
        telefonoCtrl.text = data.telefono;
        correoCtrl.text = data.correo;
        direccionCtrl.text = data.direccion;
        departamentoSeleccionado = data.toMap()['departamento'];
        ciudadSeleccionada = data.toMap()['ciudad'];
        horarioLVctrl.text = data.toMap()['horarioLV'] ?? '';
        horarioSabCtrl.text = data.toMap()['horarioSab'] ?? '';
      });
    }
  }

  Future<void> _guardarCambios() async {
    if (user == null) return;

    final updatedData = VeterinaryModel(
      id: user!.uid,
      nombre: nombreCtrl.text,
      direccion: direccionCtrl.text,
      telefono: telefonoCtrl.text,
      nit: nitCtrl.text,
      correo: correoCtrl.text,
    ).toMap();

    // Campos adicionales que no están en el modelo base
    updatedData.addAll({
      'departamento': departamentoSeleccionado,
      'ciudad': ciudadSeleccionada,
      'horarioLV': horarioLVctrl.text,
      'horarioSab': horarioSabCtrl.text,
    });

    await controller.updateVeterinary(user!.uid, VeterinaryModel.fromMap(updatedData, user!.uid));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade50,
      appBar: AppBar(
        backgroundColor: Colors.green.shade700,
        title: const Text('Datos de la Veterinaria'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSectionCard(
              icon: Icons.info,
              title: "Información General",
              children: [
                _buildTextField("Nombre de la Veterinaria", nombreCtrl),
                _buildTextField("NIT", nitCtrl),
                _buildTextField("Teléfono Principal", telefonoCtrl),
                _buildTextField("Email", correoCtrl),
              ],
            ),
            const SizedBox(height: 16),

            _buildSectionCard(
              icon: Icons.location_on,
              title: "Ubicación",
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildDropdown(
                        label: "Departamento",
                        value: departamentoSeleccionado,
                        items: departamentos,
                        onChanged: (value) {
                          setState(() {
                            departamentoSeleccionado = value;
                            ciudadSeleccionada = null;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildDropdown(
                        label: "Ciudad",
                        value: ciudadSeleccionada,
                        items: ciudadesPorDepartamento[departamentoSeleccionado] ?? [],
                        onChanged: (value) {
                          setState(() {
                            ciudadSeleccionada = value;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                _buildTextField("Dirección Completa", direccionCtrl),
              ],
            ),
            const SizedBox(height: 16),

            _buildSectionCard(
              icon: Icons.access_time,
              title: "Horarios de Atención",
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField("Lunes a Viernes", horarioLVctrl),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildTextField("Sábados", horarioSabCtrl),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Botones de acción
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _guardarCambios,
                    icon: const Icon(Icons.save, color: Colors.white),
                    label: const Text("Guardar Cambios", style: TextStyle(color: Colors.white)),

                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Get.back(),
              child: const Text("Cancelar", style: TextStyle(color: Colors.green)),
            ),
          ],
        ),
      ),
    );
  }

  // --- Widgets auxiliares ---
  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.green),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.green.shade400, width: 1.5),
            borderRadius: BorderRadius.circular(10),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.green),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.green.shade400, width: 1.5),
            borderRadius: BorderRadius.circular(10),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            hint: Text("Seleccionar $label"),
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
