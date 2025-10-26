import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
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

  // Campos de ubicación actual
  double? latitud;
  double? longitud;
  String? ciudad;
  String? direccion;

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
        horarioLVctrl.text = data.horarioLV ?? '';
        horarioSabCtrl.text = data.horarioSab ?? '';
        latitud = data.latitud;
        longitud = data.longitud;
        direccion = data.direccion;
        ciudad = data.ciudad;
      });
    }
  }

  Future<void> _guardarCambios() async {
    if (user == null) return;

    final updatedData = VeterinaryModel(
      id: user!.uid,
      nombre: nombreCtrl.text,
      direccion: direccion ?? '',
      telefono: telefonoCtrl.text,
      nit: nitCtrl.text,
      correo: correoCtrl.text,
      horarioLV: horarioLVctrl.text,
      horarioSab: horarioSabCtrl.text,
      latitud: latitud,
      longitud: longitud,
      ciudad: ciudad,
    );

    await controller.updateVeterinary(user!.uid, updatedData);
  }

  Future<void> _obtenerUbicacionActual() async {
  final ubicacion = await controller.getCurrentLocationData();
  if (ubicacion == null) return;

  setState(() {
    latitud = ubicacion['latitud'];
    longitud = ubicacion['longitud'];
    direccion = ubicacion['direccion'];
  });
}


  void _abrirEnGoogleMaps() async {
    if (latitud == null || longitud == null) return;
    final url =
        'https://www.google.com/maps?q=$latitud,$longitud';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      Get.snackbar('Error', 'No se pudo abrir Google Maps');
    }
  }

  void _eliminarUbicacion() {
    setState(() {
      latitud = null;
      longitud = null;
      direccion = null;
      ciudad = null;
    });
    Get.snackbar('Ubicación eliminada', 'Puedes seleccionar una nueva ubicación');
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

            // 🟢 Nueva sección de ubicación actual
            _buildSectionCard(
              icon: Icons.location_on,
              title: "Agregar ubicación actual",
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _obtenerUbicacionActual,
                  icon: const Icon(Icons.my_location, color: Colors.white),
                  label: const Text(
                    "Obtener ubicación actual",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(height: 10),

                if (latitud != null && longitud != null) ...[
                  Text(
                    "📍 Dirección: ${direccion ?? 'Desconocida'}",
                    style: const TextStyle(fontSize: 14),
                  ),
                  Text("🏙️ Ciudad: ${ciudad ?? 'No disponible'}"),
                  Text("🌎 Coordenadas: ($latitud, $longitud)"),
                  const SizedBox(height: 8),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _abrirEnGoogleMaps,
                        icon: const Icon(Icons.map, color: Colors.white),
                        label: const Text("Ver en Google Maps",
                            style: TextStyle(color: Colors.white)),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _eliminarUbicacion,
                        icon: const Icon(Icons.delete, color: Colors.white),
                        label: const Text("Eliminar ubicación",
                            style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ],
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
                        child: _buildTextField("Lunes a Viernes", horarioLVctrl)),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _buildTextField("Sábados", horarioSabCtrl)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Botón de guardar cambios
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _guardarCambios,
                    icon: const Icon(Icons.save, color: Colors.white),
                    label: const Text("Guardar Cambios",
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Get.back(),
              child: const Text("Cancelar",
                  style: TextStyle(color: Colors.green)),
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
                Text(title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
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
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
      ),
    );
  }
}
