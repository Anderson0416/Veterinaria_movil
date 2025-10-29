import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:veterinaria_movil/controllers/veterinarian_controller.dart';
import 'package:veterinaria_movil/moldes/veterinarian_models.dart';
import 'package:veterinaria_movil/ui/home/login_screens.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class VeterinarianProfileScreen extends StatefulWidget {
  final VeterinarianModel vet;

  const VeterinarianProfileScreen({super.key, required this.vet});

  @override
  State<VeterinarianProfileScreen> createState() => _VeterinarianProfileScreenState();
}

class _VeterinarianProfileScreenState extends State<VeterinarianProfileScreen> {
  final VeterinarianController _vetController = Get.find<VeterinarianController>();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Controladores de texto
  late TextEditingController nombreCtrl;
  late TextEditingController apellidoCtrl;
  late TextEditingController emailCtrl;
  late TextEditingController telefonoCtrl;
  late TextEditingController fechaNacimientoCtrl;
  late TextEditingController tipoDocumentoCtrl;
  late TextEditingController numeroDocumentoCtrl;
  late TextEditingController departamentoCtrl;
  late TextEditingController ciudadCtrl;
  late TextEditingController direccionCtrl;
  late TextEditingController especialidadCtrl;

  bool isLoading = false;

  // Nuevos campos para locations
  Map<String, List<String>> locationMap = {};
  List<String> departamentos = [];
  List<String> ciudades = [];
  String? selectedDepartamento;
  String? selectedCiudad;
  bool locationsLoading = true;

  @override
  void initState() {
    super.initState();
    final v = widget.vet;
    nombreCtrl = TextEditingController(text: v.nombre);
    apellidoCtrl = TextEditingController(text: v.apellido);
    emailCtrl = TextEditingController(text: v.email);
    telefonoCtrl = TextEditingController(text: v.telefono);
    fechaNacimientoCtrl = TextEditingController(text: v.fechaNacimiento);
    tipoDocumentoCtrl = TextEditingController(text: v.tipoDocumento);
    numeroDocumentoCtrl = TextEditingController(text: v.numeroDocumento);
    departamentoCtrl = TextEditingController(text: v.departamento);
    ciudadCtrl = TextEditingController(text: v.ciudad);
    direccionCtrl = TextEditingController(text: v.direccion);
    especialidadCtrl = TextEditingController(text: v.especialidad);

    // Cargar ubicaciones desde JSON
    _loadLocations();
  }

  @override
  void dispose() {
    nombreCtrl.dispose();
    apellidoCtrl.dispose();
    emailCtrl.dispose();
    telefonoCtrl.dispose();
    fechaNacimientoCtrl.dispose();
    tipoDocumentoCtrl.dispose();
    numeroDocumentoCtrl.dispose();
    departamentoCtrl.dispose();
    ciudadCtrl.dispose();
    direccionCtrl.dispose();
    especialidadCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadLocations() async {
    try {
      // Load JSON from assets/data where the project declares the asset
      final jsonString = await rootBundle.loadString('assets/data/colombia_locations.json');
      final decoded = json.decode(jsonString);

      // Support two possible formats:
      // 1) Map<String, List<String>> { "Departamento": ["Ciudad1","Ciudad2"] }
      // 2) List of objects [ { "departamento": "Antioquia", "ciudades": [...] }, ... ]
      if (decoded is Map<String, dynamic>) {
        locationMap = decoded.map((key, value) => MapEntry(key, List<String>.from(value)));
      } else if (decoded is List) {
        locationMap = {};
        for (final item in decoded) {
          if (item is Map<String, dynamic>) {
            final dept = (item['departamento'] ?? item['departamento_name'] ?? '').toString();
            final citiesRaw = item['ciudades'] ?? item['cities'] ?? item['municipios'];
            if (dept.isNotEmpty && citiesRaw is List) {
              locationMap[dept] = citiesRaw.map((c) => c.toString()).toList();
            }
          }
        }
      } else {
        throw Exception('Formato JSON de ubicaciones no reconocido');
      }

      departamentos = locationMap.keys.toList()..sort();

      // establecer selección inicial si existe en el vet
      if (departamentoCtrl.text.isNotEmpty && locationMap.containsKey(departamentoCtrl.text)) {
        selectedDepartamento = departamentoCtrl.text;
        ciudades = locationMap[selectedDepartamento] ?? [];
        if (ciudadCtrl.text.isNotEmpty && ciudades.contains(ciudadCtrl.text)) {
          selectedCiudad = ciudadCtrl.text;
        } else {
          selectedCiudad = null;
        }
      } else {
        // intentar usar el primer departamento si no hay valor
        selectedDepartamento = widget.vet.departamento.isNotEmpty && locationMap.containsKey(widget.vet.departamento)
            ? widget.vet.departamento
            : (departamentos.isNotEmpty ? departamentos.first : null);
        if (selectedDepartamento != null) {
          ciudades = locationMap[selectedDepartamento] ?? [];
          selectedCiudad = (widget.vet.ciudad.isNotEmpty && ciudades.contains(widget.vet.ciudad)) ? widget.vet.ciudad : null;
        }
      }

      // sincronizar controllers
      if (selectedDepartamento != null) departamentoCtrl.text = selectedDepartamento!;
      if (selectedCiudad != null) ciudadCtrl.text = selectedCiudad!;
    } catch (e) {
      // Si falla la carga, dejamos los campos como texto normal y avisamos
      print('Error cargando locations: $e');
      Get.snackbar('Error', 'No se pudieron cargar ubicaciones: $e');
    } finally {
      setState(() => locationsLoading = false);
    }
  }

  Future<void> _guardarCambios() async {
    setState(() => isLoading = true);
    try {
      final vetActualizado = VeterinarianModel(
        id: widget.vet.id,
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
        especialidad: especialidadCtrl.text.trim(),
        veterinaryId: widget.vet.veterinaryId,
      );

      await _vetController.updateVeterinarian(widget.vet.id!, vetActualizado);
      Get.snackbar("Éxito", "Datos actualizados correctamente ✅",
          backgroundColor: Colors.green.shade50);
    } catch (e) {
      Get.snackbar("Error", "No se pudieron guardar los cambios: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _cerrarSesion() async {
    await _auth.signOut();
    Get.offAll(() => const LoginScreens());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FDF8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF388E3C),
        title: const Text("Perfil del Veterinario"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _cerrarSesion,
            tooltip: "Cerrar sesión",
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Text(
                  "Información Personal",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF388E3C),
                  ),
                ),
                const SizedBox(height: 16),

                _buildTextField("Nombre", nombreCtrl),
                _buildTextField("Apellido", apellidoCtrl),
                _buildTextField("Correo Electrónico", emailCtrl, enabled: false),
                _buildTextField("Teléfono", telefonoCtrl),
                _buildTextField("Fecha de Nacimiento", fechaNacimientoCtrl),
                _buildTextField("Tipo de Documento", tipoDocumentoCtrl),
                _buildTextField("Número de Documento", numeroDocumentoCtrl),

                // reemplazamos los campos de departamento/ciudad por dropdowns
                locationsLoading
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: const [
                            SizedBox(width: 16),
                            CircularProgressIndicator(color: Color(0xFF388E3C)),
                            SizedBox(width: 12),
                            Text('Cargando ubicaciones...')
                          ],
                        ),
                      )
                    : _buildLocationFields(),

                _buildTextField("Dirección", direccionCtrl),
                _buildTextField("Especialidad", especialidadCtrl),

                const SizedBox(height: 24),
                isLoading
                    ? const CircularProgressIndicator(color: Color(0xFF388E3C))
                    : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _guardarCambios,
                          icon: const Icon(Icons.save, color: Colors.white),
                          label: const Text(
                            "Guardar Cambios",
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF388E3C),
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
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController ctrl,
      {bool enabled = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: ctrl,
        enabled: enabled,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xFF388E3C)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Color(0xFF388E3C)),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  // Nuevo: construye los dropdowns para departamento y ciudad
  Widget _buildLocationFields() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: DropdownButtonFormField<String>(
            value: selectedDepartamento,
            decoration: InputDecoration(
              labelText: 'Departamento',
              labelStyle: const TextStyle(color: Color(0xFF388E3C)),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Color(0xFF388E3C)),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            items: departamentos
                .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                .toList(),
            onChanged: (val) {
              setState(() {
                selectedDepartamento = val;
                departamentoCtrl.text = val ?? '';
                ciudades = (val != null) ? (locationMap[val] ?? []) : [];
                // reset ciudad si no pertenece al nuevo departamento
                if (selectedCiudad == null || !ciudades.contains(selectedCiudad)) {
                  selectedCiudad = null;
                  ciudadCtrl.text = '';
                }
              });
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: DropdownButtonFormField<String>(
            value: selectedCiudad,
            decoration: InputDecoration(
              labelText: 'Ciudad',
              labelStyle: const TextStyle(color: Color(0xFF388E3C)),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Color(0xFF388E3C)),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            items: ciudades
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (val) {
              setState(() {
                selectedCiudad = val;
                ciudadCtrl.text = val ?? '';
              });
            },
          ),
        ),
      ],
    );
  }
}
