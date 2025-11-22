import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart'; // 🔹 AGREGADO
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

  // NUEVOS: Campos para horario LV y Sábado
  final horarioLVInicioCtrl = TextEditingController();
  final horarioLVFinCtrl = TextEditingController();
  final horarioSabInicioCtrl = TextEditingController();
  final horarioSabFinCtrl = TextEditingController();

  // Dropdowns
  String? departamentoSeleccionado;
  String? ciudadSeleccionada;

  final List<String> departamentos = [];
  final Map<String, List<String>> ciudadesPorDepartamento = {};

  // Coordenadas
  double? latitud;
  double? longitud;

  @override
  void initState() {
    super.initState();
    _loadLocations().then((_) => _loadVeterinaryData());
  }

  Future<void> _loadLocations() async {
    try {
      final jsonStr = await rootBundle.loadString('assets/data/colombia_locations.json');
      final data = jsonDecode(jsonStr);

      departamentos.clear();
      ciudadesPorDepartamento.clear();

      if (data is Map<String, dynamic>) {
        if (data.containsKey('departamentos') && data['departamentos'] is List) {
          for (final entry in data['departamentos']) {
            if (entry is Map<String, dynamic>) {
              final dept = entry['departamento']?.toString() ?? '';
              final cities = <String>[];
              if (entry['ciudades'] is List) {
                for (final c in entry['ciudades']) {
                  cities.add(c.toString());
                }
              }
              if (dept.isNotEmpty) {
                departamentos.add(dept);
                ciudadesPorDepartamento[dept] = cities;
              }
            }
          }
        } else {
          for (final key in data.keys) {
            final value = data[key];
            if (value is List) {
              departamentos.add(key);
              ciudadesPorDepartamento[key] = value.map((e) => e.toString()).toList();
            }
          }
        }
      } else if (data is List) {
        for (final item in data) {
          if (item is Map<String, dynamic>) {
            final dept = item['departamento']?.toString() ?? '';
            final cities = <String>[];
            if (item['ciudades'] is List) {
              for (final c in item['ciudades']) {
                cities.add(c.toString());
              }
            }
            if (dept.isNotEmpty) {
              departamentos.add(dept);
              ciudadesPorDepartamento[dept] = cities;
            }
          }
        }
      }

      departamentos.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      setState(() {});
    } catch (e) {
      departamentos.clear();
      ciudadesPorDepartamento.clear();
      departamentos.addAll([
        'Cundinamarca',
        'Antioquia',
        'Valle del Cauca',
        'Atlántico',
        'Cesar',
        'Santander',
      ]);
      ciudadesPorDepartamento.addAll({
        'Cundinamarca': ['Bogotá', 'Soacha', 'Fusagasugá'],
        'Antioquia': ['Medellín', 'Envigado', 'Bello'],
        'Valle del Cauca': ['Cali', 'Palmira', 'Buenaventura'],
        'Atlántico': ['Barranquilla', 'Soledad'],
        'Cesar': ['Valledupar', 'Bosconia', 'Aguachica'],
        'Santander': ['Bucaramanga', 'Floridablanca'],
      });
      print('Warning: failed to load colombia_locations.json: $e');
      setState(() {});
    }
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
        latitud = data.latitud;
        longitud = data.longitud;
        departamentoSeleccionado = data.departamento;
        ciudadSeleccionada = data.ciudad;

        // Separar horarios de lunes a viernes
        if (data.horarioLV != null && data.horarioLV!.contains('-')) {
          final partes = data.horarioLV!.split('-');
          horarioLVInicioCtrl.text = partes[0].trim();
          horarioLVFinCtrl.text = partes.length > 1 ? partes[1].trim() : '';
        }

        //  Separar horarios de sábado
        if (data.horarioSab != null && data.horarioSab!.contains('-')) {
          final partes = data.horarioSab!.split('-');
          horarioSabInicioCtrl.text = partes[0].trim();
          horarioSabFinCtrl.text = partes.length > 1 ? partes[1].trim() : '';
        }
      });
    }
  }

  Future<void> _guardarCambios() async {
    if (user == null) return;

    final horarioLV = "${horarioLVInicioCtrl.text} - ${horarioLVFinCtrl.text}";
    final horarioSab = "${horarioSabInicioCtrl.text} - ${horarioSabFinCtrl.text}";

    final updatedData = VeterinaryModel(
      id: user!.uid,
      nombre: nombreCtrl.text,
      direccion: direccionCtrl.text,
      telefono: telefonoCtrl.text,
      nit: nitCtrl.text,
      correo: correoCtrl.text,
      horarioLV: horarioLV,
      horarioSab: horarioSab,
      latitud: latitud,
      longitud: longitud,
      ciudad: ciudadSeleccionada,
      departamento: departamentoSeleccionado,
    );

    await FirebaseFirestore.instance.collection('veterinarias').doc(user!.uid).update({
      'nombre': updatedData.nombre,
      'direccion': updatedData.direccion,
      'telefono': updatedData.telefono,
      'nit': updatedData.nit,
      'correo': updatedData.correo,
      'horarioLV': updatedData.horarioLV,
      'horarioSab': updatedData.horarioSab,
      'latitud': updatedData.latitud ?? FieldValue.delete(),
      'longitud': updatedData.longitud ?? FieldValue.delete(),
      'ciudad': updatedData.ciudad,
      'departamento': updatedData.departamento,
    });

    Get.snackbar('Guardado', 'Cambios guardados exitosamente');
  }
  Future<void> _obtenerUbicacionActual() async {
    bool serviceEnabled;
    LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      Get.snackbar(
        'Ubicación deshabilitada',
        'Por favor activa el GPS en tu dispositivo',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
      return;
    }

    permission = await Geolocator.checkPermission();
    
    if (permission == LocationPermission.denied) {

      permission = await Geolocator.requestPermission();
      
      if (permission == LocationPermission.denied) {
        Get.snackbar(
          'Permisos denegados',
          'Necesitamos acceso a tu ubicación para continuar',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      Get.defaultDialog(
        title: 'Permisos requeridos',
        middleText: 'Los permisos de ubicación están permanentemente denegados. Por favor, actívalos desde la configuración de tu dispositivo.',
        textConfirm: 'Abrir configuración',
        textCancel: 'Cancelar',
        confirmTextColor: Colors.white,
        onConfirm: () async {
          Get.back();
          await Geolocator.openAppSettings();
        },
      );
      return;
    }

    try {
      Get.snackbar(
        'Obteniendo ubicación',
        'Por favor espera...',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.blue,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
        showProgressIndicator: true,
      );

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        latitud = position.latitude;
        longitud = position.longitude;
      });

      Get.snackbar(
        '¡Ubicación obtenida!',
        'Coordenadas registradas correctamente',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'No se pudo obtener la ubicación: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
  }

  void _abrirEnGoogleMaps() async {
    if (latitud == null || longitud == null) return;
    final url = 'https://www.google.com/maps?q=$latitud,$longitud';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      Get.snackbar('Error', 'No se pudo abrir Google Maps');
    }
  }

  Future<void> _eliminarUbicacion() async {
    if (user == null) {
      Get.snackbar('Error', 'No hay sesión activa');
      return;
    }

    try {
      await controller.removeVeterinaryCoordinates(user!.uid);

      setState(() {
        latitud = null;
        longitud = null;
      });

      Get.snackbar('Ubicación', 'Coordenadas eliminadas exitosamente');
    } catch (e) {
      Get.snackbar('Error', 'No se pudieron eliminar las coordenadas: $e');
    }
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
                _buildTextField("Dirección", direccionCtrl),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _obtenerUbicacionActual,
                        icon: const Icon(Icons.my_location, color: Colors.white),
                        label: const Text("Obtener ubicación actual", style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (latitud != null && longitud != null) ...[
                  Text("🌎 Coordenadas: ($latitud, $longitud)"),
                  const SizedBox(height: 8),
                  _buildResponsiveLocationButtons(),
                ],
              ],
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              icon: Icons.access_time,
              title: "Horarios de Atención",
              children: [
                const Text("Lunes a Viernes"),
                Row(
                  children: [
                    Expanded(child: _buildTextField("Hora de apertura", horarioLVInicioCtrl)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildTextField("Hora de cierre", horarioLVFinCtrl)),
                  ],
                ),
                const SizedBox(height: 10),
                const Text("Sábados"),
                Row(
                  children: [
                    Expanded(child: _buildTextField("Hora de apertura", horarioSabInicioCtrl)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildTextField("Hora de cierre", horarioSabFinCtrl)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
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
  Widget _buildSectionCard({required IconData icon, required String title, required List<Widget> children}) {
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
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
    final esCampoHora = label.toLowerCase().contains("hora");

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        readOnly: esCampoHora,
        onTap: esCampoHora
            ? () async {
                final horaActual = TimeOfDay.now();
                final horaSeleccionada = await showTimePicker(
                  context: context,
                  initialTime: horaActual,
                );

                if (horaSeleccionada != null) {
                  final horaFormateada = horaSeleccionada.format(context);
                  setState(() {
                    controller.text = horaFormateada;
                  });
                }
              }
            : null,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.green),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.green.shade400, width: 1.5),
            borderRadius: BorderRadius.circular(10),
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          suffixIcon: esCampoHora ? const Icon(Icons.access_time, color: Colors.green) : null,
        ),
      ),
    );
  }

  Widget _buildDropdown({required String label, required String? value, required List<String> items, required Function(String?) onChanged}) {
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
            items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
            onChanged: onChanged,
            isExpanded: true,
          ),
        ),
      ),
    );
  }

  Widget _buildResponsiveLocationButtons() {
    return LayoutBuilder(builder: (context, constraints) {
      final isNarrow = constraints.maxWidth < 350;
      
      if (isNarrow) {
        // Vertical stack on narrow screens
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: _abrirEnGoogleMaps,
              icon: const Icon(Icons.map, color: Colors.white),
              label: const Text("Ver en Google Maps", style: TextStyle(color: Colors.white), overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: _eliminarUbicacion,
              icon: const Icon(Icons.delete, color: Colors.white),
              label: const Text("Eliminar ubicación", style: TextStyle(color: Colors.white), overflow: TextOverflow.ellipsis),
            ),
          ],
        );
      }

      // Horizontal row on wider screens
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _abrirEnGoogleMaps,
              icon: const Icon(Icons.map, color: Colors.white),
              label: const Text("Ver en Google Maps", style: TextStyle(color: Colors.white), overflow: TextOverflow.ellipsis),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _eliminarUbicacion,
              icon: const Icon(Icons.delete, color: Colors.white),
              label: const Text("Eliminar ubicación", style: TextStyle(color: Colors.white), overflow: TextOverflow.ellipsis),
            ),
          ),
        ],
      );
    });
  }
}