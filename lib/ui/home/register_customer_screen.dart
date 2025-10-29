import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:veterinaria_movil/controllers/customer_controller.dart';
import 'package:veterinaria_movil/moldes/customer_model.dart';
import 'package:veterinaria_movil/ui/home/login_screens.dart';

class RegisterCustomerScreen extends StatefulWidget {
  const RegisterCustomerScreen({super.key});

  @override
  State<RegisterCustomerScreen> createState() => _RegisterCustomerScreenState();
}

class _RegisterCustomerScreenState extends State<RegisterCustomerScreen> {
  // Controladores de texto
  final nombreCtrl = TextEditingController();
  final apellidoCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final telCtrl = TextEditingController();
  final fechaCtrl = TextEditingController();
  DateTime? selectedFecha;
  final docNumCtrl = TextEditingController();
  final direccionCtrl = TextEditingController();


  String tipoDoc = "CC";
  // Ubicaciones
  Map<String, List<String>> locationMap = {};
  List<String> departamentos = [];
  List<String> ciudades = [];
  String? selectedDepartamento;
  String? selectedCiudad;
  bool locationsLoading = true;

  late final CustomerController customerController;

  @override
  void initState() {
    super.initState();
    customerController = Get.find();
    _loadLocations();
  }

  Future<void> _loadLocations() async {
    try {
      final jsonString = await rootBundle.loadString('assets/data/colombia_locations.json');
      final decoded = json.decode(jsonString);
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
      // Selección inicial
      selectedDepartamento = departamentos.isNotEmpty ? departamentos.first : null;
      ciudades = selectedDepartamento != null ? locationMap[selectedDepartamento] ?? [] : [];
      selectedCiudad = ciudades.isNotEmpty ? ciudades.first : null;
    } catch (e) {
      print('Error cargando locations: $e');
      Get.snackbar('Error', 'No se pudieron cargar ubicaciones: $e');
    } finally {
      setState(() => locationsLoading = false);
    }
  }

  @override
  void dispose() {
    nombreCtrl.dispose();
    apellidoCtrl.dispose();
    emailCtrl.dispose();
    telCtrl.dispose();
    fechaCtrl.dispose();
    docNumCtrl.dispose();
    direccionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                    icon: Icons.calendar_today,
                    readOnly: true,
                    onTap: () async {
                  // Mostrar date picker
                  final now = DateTime.now();
                  final firstDate = DateTime(1900);
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedFecha ?? DateTime(now.year - 20),
                    firstDate: firstDate,
                    lastDate: now,
                    helpText: 'Selecciona fecha de nacimiento',
                  );
                  if (picked != null) {
                    setState(() {
                      selectedFecha = picked;
                      // Formato dinámico según locale del dispositivo
                      final locale = Localizations.localeOf(context).toString();
                      final formatted = DateFormat.yMMMMd(locale).format(picked);
                      fechaCtrl.text = formatted;
                    });
                  }
                }),
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
                locationsLoading
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: const [
                            SizedBox(width: 16),
                            CircularProgressIndicator(color: Colors.green),
                            SizedBox(width: 12),
                            Text('Cargando ubicaciones...')
                          ],
                        ),
                      )
                    : _buildLocationFields(),
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
                    departamento: selectedDepartamento ?? '',
                    ciudad: selectedCiudad ?? '',
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
      {IconData icon = Icons.text_fields,
      bool readOnly = false,
      VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        onTap: onTap,
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

  // Dropdowns de departamento y ciudad
  Widget _buildLocationFields() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: DropdownButtonFormField<String>(
            value: selectedDepartamento,
            decoration: InputDecoration(
              labelText: 'Departamento',
              labelStyle: const TextStyle(color: Colors.green),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.green.shade400),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            items: departamentos.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
            onChanged: (val) {
              setState(() {
                selectedDepartamento = val;
                // Actualizar ciudades
                ciudades = (val != null) ? (locationMap[val] ?? []) : [];
                selectedCiudad = ciudades.isNotEmpty ? ciudades.first : null;
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
              labelStyle: const TextStyle(color: Colors.green),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.green.shade400),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            items: ciudades.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (val) {
              setState(() {
                selectedCiudad = val;
              });
            },
          ),
        ),
      ],
    );
  }
}
