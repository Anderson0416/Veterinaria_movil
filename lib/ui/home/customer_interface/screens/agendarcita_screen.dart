  import 'package:flutter/material.dart';
  import 'package:get/get.dart';
  import 'package:cloud_firestore/cloud_firestore.dart';
  import 'package:veterinaria_movil/controllers/pet_controller.dart';
  import 'package:veterinaria_movil/controllers/appointment_controllers.dart';
  import 'package:veterinaria_movil/moldes/appointment_model.dart';
  import 'package:veterinaria_movil/moldes/pet_model.dart';
  import 'package:firebase_auth/firebase_auth.dart';
  import 'package:geolocator/geolocator.dart';
  import 'package:url_launcher/url_launcher.dart';
  import 'package:veterinaria_movil/ui/home/customer_interface/screens/customer_menu_screen.dart';

  import '../widgets/clinic_info_card.dart';
  import '../widgets/cita_dropdown_field.dart';
  import '../widgets/cita_text_field.dart';

  class AgendarCitaScreen extends StatefulWidget {
    const AgendarCitaScreen({super.key});

    @override
    State<AgendarCitaScreen> createState() => _AgendarCitaScreenState();
  }

  class _AgendarCitaScreenState extends State<AgendarCitaScreen> {
    final _formKey = GlobalKey<FormState>();

    final petController = PetController();
    final fechaCtrl = TextEditingController();
    final horaCtrl = TextEditingController();
    final observacionesCtrl = TextEditingController();
    final appointmentController = AppointmentController();

    String? mascotaSeleccionada;
    String? servicioSeleccionadoId;
    String? servicioSeleccionadoNombre;
    String? veterinarioSeleccionadoId;
    String? veterinarioSeleccionadoNombre;
    DateTime? fechaSeleccionada;
    TimeOfDay? horaSeleccionada;
    String? modalidadSeleccionada;
    String? selectedClinicId;
    double? precioServicioSeleccionado;

    String? clinicaNombre;
    String? clinicaDireccion;
    String? clinicaTelefono;

    double? clinicaLat;
    double? clinicaLng;
    double? ubicacionLat;
    double? ubicacionLng;

    String? direccionVeterinaria;
    String? direccionUsuario;

    final List<String> modalidades = ['Presencial', 'Domicilio'];

    @override
    void dispose() {
      observacionesCtrl.dispose();
      fechaCtrl.dispose();
      horaCtrl.dispose();
      super.dispose();
    }

    Future<void> _pickDateSimple() async {
      final now = DateTime.now();
      final picked = await showDatePicker(
        context: context,
        initialDate: now,
        firstDate: now,
        lastDate: DateTime(now.year + 2),
      );
      if (picked != null) {
        setState(() {
          fechaSeleccionada = picked;
          fechaCtrl.text = '${picked.day}/${picked.month}/${picked.year}';
        });
      }
    }

    Future<void> _pickTimeSimple() async {
      final now = TimeOfDay.now();
      final picked = await showTimePicker(context: context, initialTime: now);
      if (picked != null) {
        setState(() {
          horaSeleccionada = picked;
          horaCtrl.text = picked.format(context);
        });
      }
    }

    Future<Position> _obtenerUbicacionCliente() async {
      bool enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        await Geolocator.openLocationSettings();
        throw Exception("Activa la ubicación.");
      }

      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) {
        throw Exception("Permiso denegado permanentemente.");
      }

      return await Geolocator.getCurrentPosition();
    }

    Future<void> _abrirGoogleMaps() async {
      if (ubicacionLat == null || ubicacionLng == null) {
        Get.snackbar("Error", "No hay ubicación seleccionada.");
        return;
      }

      final url =
          "https://www.google.com/maps/search/?api=1&query=$ubicacionLat,$ubicacionLng";

      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } else {
        Get.snackbar("Error", "No se pudo abrir Google Maps");
      }
    }

  Future<void> _confirmarCita() async {
      if (!_formKey.currentState!.validate()) {
        Get.snackbar("Error", "Completa todos los campos obligatorios.");
        return;
      }

      if (mascotaSeleccionada == null ||
          servicioSeleccionadoId == null ||
          fechaSeleccionada == null ||
          horaSeleccionada == null ||
          modalidadSeleccionada == null) {
        Get.snackbar("Campos faltantes", "Completa todos los datos de la cita.");
        return;
      }

      if (ubicacionLat == null || ubicacionLng == null) {
        Get.snackbar("Ubicación", "Selecciona modalidad para obtener ubicación.");
        return;
      }

      final fechaHora = DateTime(
        fechaSeleccionada!.year,
        fechaSeleccionada!.month,
        fechaSeleccionada!.day,
        horaSeleccionada!.hour,
        horaSeleccionada!.minute,
      );

      final pets = await petController
          .getPetsStream(FirebaseAuth.instance.currentUser!.uid)
          .first;

      final petObj = pets.firstWhere(
        (p) => p.nombre == mascotaSeleccionada,
        orElse: () => throw Exception("Mascota no encontrada"),
      );

      final userId = FirebaseAuth.instance.currentUser!.uid;
      String clienteNombre = 'Cliente';
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('customers')
            .doc(userId)
            .get();
        
        if (userDoc.exists) {
          final data = userDoc.data();
          final nombre = data?['nombre'] ?? '';
          final apellido = data?['apellido'] ?? '';
          clienteNombre = '$nombre $apellido'.trim();
          if (clienteNombre.isEmpty) clienteNombre = 'Cliente';
        }
      } catch (e) {
        print('Error obteniendo nombre del cliente: $e');
      }

      final String direccionCita =
          modalidadSeleccionada == "Presencial"
              ? (direccionVeterinaria ?? "")
              : (direccionUsuario ?? "");

      final cita = CitaModel(
        id: null,
        duenoId: userId,
        mascotaId: petObj.id!,
        veterinariaId: selectedClinicId!,
        veterinarioId: veterinarioSeleccionadoId ?? "",
        servicioId: servicioSeleccionadoId!,
        precioServicio: precioServicioSeleccionado ?? 0.0,
        fecha: fechaHora,
        hora: horaSeleccionada!.format(context),
        direccion: direccionCita,
        latitud: ubicacionLat!,
        longitud: ubicacionLng!,
        estado: "pendiente",
        pagado: false,
        observaciones: observacionesCtrl.text.trim(),
      );

      try {
        final idCita = await appointmentController.crearCita(cita);
        await FirebaseFirestore.instance
            .collection('appointments')
            .doc(idCita)
            .update({
              'mascotaNombre': mascotaSeleccionada ?? 'Sin nombre',
              'clienteNombre': clienteNombre,
              'tipoServicio': servicioSeleccionadoNombre?.split(' — ').first ?? 'Consulta',
            });

        Get.snackbar(
          "Cita creada",
          "La cita fue registrada exitosamente.",
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );

        await Future.delayed(const Duration(milliseconds: 800));
        Get.offAll(() => const CustomerMenuScreen());

      } catch (e) {
        Get.snackbar(
          "Error",
          "No se pudo guardar la cita: $e",
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    }

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        backgroundColor: Colors.green.shade50,
        appBar: AppBar(
          backgroundColor: Colors.green.shade700,
          title: const Text('Agendar Nueva Cita'),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('veterinarias')
                    .snapshots(),
                builder: (context, snapClinicas) {
                  if (snapClinicas.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator(
                            color: Colors.green));
                  }
                  final docs = snapClinicas.data?.docs ?? [];
                  final clinicNames = docs
                      .map<String>((d) =>
                          (d.data() as Map<String, dynamic>)['nombre']
                                  ?.toString() ??
                              'Veterinaria')
                      .toList();

                  return Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      CitaDropdownField(
                        label: 'Seleccionar Clínica',
                        value: clinicaNombre,
                        items: clinicNames,
                        onChanged: (v) {
                          if (v == null) return;
                          QueryDocumentSnapshot? match;
                          for (var d in docs) {
                            final name =
                                (d.data() as Map<String, dynamic>)[
                                            'nombre']
                                        ?.toString() ??
                                    '';
                            if (name == v) {
                              match = d;
                              break;
                            }
                          }
                          if (match != null) {
                            final data =
                                match.data() as Map<String, dynamic>;
                            setState(() {
                              selectedClinicId = match!.id;
                              clinicaNombre = data['nombre'];
                              clinicaDireccion =
                                  data['direccion'];
                              clinicaTelefono =
                                  data['telefono'];

                              clinicaLat =
                                  (data['latitud'] ?? 0)
                                      .toDouble();
                              clinicaLng =
                                  (data['longitud'] ?? 0)
                                      .toDouble();

                              direccionVeterinaria =
                                  data['direccion']?.toString();

                              ubicacionLat = null;
                              ubicacionLng = null;

                              servicioSeleccionadoId = null;
                              servicioSeleccionadoNombre =
                                  null;
                              veterinarioSeleccionadoId =
                                  null;
                              veterinarioSeleccionadoNombre =
                                  null;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      ClinicInfoCard(
                        nombre:
                            clinicaNombre ?? 'Veterinaria',
                        direccion:
                            clinicaDireccion ?? '',
                        telefono:
                            clinicaTelefono ?? '',
                      ),
                      const SizedBox(height: 20),
                    ],
                  );
                },
              ),

              Form(
                key: _formKey,
                child: Column(
                  children: [
                    Card(
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(16)),
                      elevation: 2,
                      child: Padding(
                        padding:
                            const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Información de la Cita',
                              style: TextStyle(
                                  color: Colors.green,
                                  fontWeight:
                                      FontWeight.bold,
                                  fontSize: 16),
                            ),
                            const SizedBox(height: 12),

                            StreamBuilder<List<PetModel>>(
                              stream: petController.getPetsStream(
                                  FirebaseAuth.instance
                                          .currentUser
                                          ?.uid ??
                                      ''),
                              builder: (context,
                                  snapshot) {
                                if (snapshot
                                        .connectionState ==
                                    ConnectionState
                                        .waiting) {
                                  return const Center(
                                      child:
                                          CircularProgressIndicator(
                                              color:
                                                  Colors.green));
                                }
                                final pets =
                                    snapshot.data ??
                                        [];
                                final petNames =
                                    pets
                                        .map((p) =>
                                            p.nombre)
                                        .toList();
                                return CitaDropdownField(
                                  label: 'Mascota',
                                  value:
                                      mascotaSeleccionada,
                                  items: petNames,
                                  onChanged: (v) =>
                                      setState(() =>
                                          mascotaSeleccionada =
                                              v),
                                );
                              },
                            ),

                            const SizedBox(height: 12),

                            selectedClinicId == null
                                ? _campoDeshabilitado(
                                    'Tipo de Servicio',
                                    'Selecciona primero una clínica')
                                : _dropServicios(),

                            const SizedBox(height: 12),

                            Row(
                              children: [
                                Expanded(
                                  child:
                                      GestureDetector(
                                    onTap:
                                        _pickDateSimple,
                                    child:
                                        AbsorbPointer(
                                      child:
                                          CitaTextField(
                                        label:
                                            'Fecha',
                                        readOnly:
                                            true,
                                        controller:
                                            fechaCtrl,
                                        hint:
                                            'dd/mm/aaaa',
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                    width: 10),
                                Expanded(
                                  child:
                                      GestureDetector(
                                    onTap:
                                        _pickTimeSimple,
                                    child:
                                        AbsorbPointer(
                                      child:
                                          CitaTextField(
                                        label:
                                            'Hora',
                                        readOnly:
                                            true,
                                        controller:
                                            horaCtrl,
                                        hint:
                                            '--:--',
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            selectedClinicId == null
                                ? _campoDeshabilitado(
                                    'Veterinario (Opcional)',
                                    'Selecciona primero una clínica')
                                : _dropVets(),

                            const SizedBox(height: 12),

                            CitaDropdownField(
                              label:
                                  'Modalidad',
                              value:
                                  modalidadSeleccionada,
                              items: modalidades,
                              onChanged:
                                  (v) async {
                                setState(() {
                                  modalidadSeleccionada =
                                      v;
                                  ubicacionLat =
                                      null;
                                  ubicacionLng =
                                      null;
                                });

                                if (v ==
                                    "Presencial") {
                                  setState(() {
                                    ubicacionLat =
                                        clinicaLat;
                                    ubicacionLng =
                                        clinicaLng;

                                    direccionUsuario =
                                        null;
                                  });
                                } else if (v ==
                                    "Domicilio") {
                                  try {
                                    final pos =
                                        await _obtenerUbicacionCliente();
                                    setState(() {
                                      ubicacionLat =
                                          pos.latitude;
                                      ubicacionLng =
                                          pos.longitude;

                                      direccionUsuario =
                                          "Ubicación del cliente";
                                    });
                                  } catch (e) {
                                    Get.snackbar(
                                        "Error ubicación",
                                        e.toString());
                                  }
                                }
                              },
                            ),

                            const SizedBox(height: 12),

                            if (ubicacionLat !=
                                    null &&
                                ubicacionLng != null)
                              Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,
                                children: [
                                  ElevatedButton
                                      .icon(
                                    onPressed:
                                        _abrirGoogleMaps,
                                    icon: const Icon(
                                        Icons.map),
                                    label: const Text(
                                        "Ver ubicación en Google Maps"),
                                    style: ElevatedButton
                                        .styleFrom(
                                            backgroundColor:
                                                Colors.green,
                                            foregroundColor:
                                                Colors
                                                    .white),
                                  ),
                                  const SizedBox(
                                      height: 8),
                                  TextButton.icon(
                                    onPressed:
                                        () {
                                      setState(() {
                                        ubicacionLat =
                                            null;
                                        ubicacionLng =
                                            null;
                                        modalidadSeleccionada =
                                            null;
                                      });
                                    },
                                    icon: const Icon(
                                      Icons.close,
                                      color:
                                          Colors.red,
                                    ),
                                    label: const Text(
                                      "Quitar ubicación",
                                      style: TextStyle(
                                          color: Colors
                                              .red),
                                    ),
                                  )
                                ],
                              ),

                            const SizedBox(height: 12),

                            CitaTextField(
                              label:
                                  'Observaciones',
                              controller:
                                  observacionesCtrl,
                              hint:
                                  'Describe cualquier síntoma o información relevante...',
                              maxLines: 3,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    SizedBox(
                      width:
                          double.infinity,
                      child: ElevatedButton
                          .icon(
                        onPressed:
                            _confirmarCita,
                        icon: const Icon(Icons
                            .check_circle_outline),
                        label: const Text(
                            'Confirmar Cita'),
                        style: ElevatedButton
                            .styleFrom(
                          backgroundColor:
                              Colors.green,
                          foregroundColor:
                              Colors.white,
                          padding:
                              const EdgeInsets
                                  .symmetric(
                                  vertical:
                                      14),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                          10)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width:
                          double.infinity,
                      child: ElevatedButton(
                        onPressed: () =>
                            Get.back(),
                        style: ElevatedButton
                            .styleFrom(
                          backgroundColor:
                              Colors.white,
                          foregroundColor:
                              Colors.green,
                          padding:
                              const EdgeInsets
                                  .symmetric(
                                  vertical:
                                      14),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(
                                        10),
                            side:
                                const BorderSide(
                                    color: Colors
                                        .green),
                          ),
                        ),
                        child: const Text(
                          'Cancelar',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    Widget _campoDeshabilitado(String label, String hint) {
      return Padding(
        padding:
            const EdgeInsets.symmetric(vertical: 6),
        child: DropdownButtonFormField<String>(
          value: null,
          decoration: InputDecoration(
            labelText: label,
            labelStyle:
                const TextStyle(color: Colors.green),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(12)),
          ),
          items: const [],
          onChanged: null,
          hint: Text(hint),
        ),
      );
    }

    Widget _dropServicios() {
      return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('types_services')
            .where('veterinaryId',
                isEqualTo: selectedClinicId)
            .snapshots(),
        builder:
            (context, snapServices) {
          if (snapServices
                  .connectionState ==
              ConnectionState.waiting) {
            return const Center(
                child:
                    CircularProgressIndicator(
                        color: Colors.green));
          }

          final docsS =
              snapServices.data?.docs ?? [];

          final serviceItems =
              docsS.map<
                  DropdownMenuItem<
                      String>>((d) {
            final data = d.data()
                as Map<String, dynamic>;
            final name =
                (data['nombre'] ?? '')
                    .toString();
            final price =
                (data['precio'] ?? '')
                    .toString();

            return DropdownMenuItem(
              value: d.id,
              child: Text(
                  "$name — \$$price"),
            );
          }).toList();

          if (serviceItems.isEmpty) {
            return _campoDeshabilitado(
                'Tipo de Servicio',
                'No hay servicios disponibles');
          }

          return Padding(
            padding:
                const EdgeInsets.symmetric(
                    vertical: 6),
            child: DropdownButtonFormField<
                String>(
              value:
                  servicioSeleccionadoId,
              isExpanded: true,
              decoration:
                  InputDecoration(
                labelText:
                    'Tipo de Servicio',
                labelStyle:
                    const TextStyle(
                        color: Colors
                            .green),
                filled: true,
                fillColor:
                    Colors.white,
                border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(
                            12)),
              ),
              items:
                  serviceItems,
              onChanged:
                  (val) {
                if (val == null)
                  return;
                final matched =
                    docsS.firstWhere(
                        (d) =>
                            d.id == val);
                final data =
                    matched.data()
                        as Map<String,
                            dynamic>;
                final name =
                    data['nombre']
                            ?.toString() ??
                        '';
                final price =
                    data['precio']
                            ?.toString() ??
                        '';
                setState(() {
                  servicioSeleccionadoId =
                      val;
                  servicioSeleccionadoNombre =
                      "$name — \$$price";
                  precioServicioSeleccionado =
                      double.tryParse(
                              price) ??
                          0.0;
                });
              },
            ),
          );
        },
      );
    }

    Widget _dropVets() {
      return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('veterinarians')
            .where('veterinaryId',
                isEqualTo: selectedClinicId)
            .snapshots(),
        builder: (context, snapVets) {
          if (snapVets.connectionState ==
              ConnectionState.waiting) {
            return const Center(
                child:
                    CircularProgressIndicator(
                        color: Colors.green));
          }

          final docsV =
              snapVets.data?.docs ?? [];
          final vetItems =
              docsV.map<
                  DropdownMenuItem<
                      String>>((d) {
            final data = d.data()
                as Map<String, dynamic>;
            final fullName =
                '${(data['nombre'] ?? '')
                    .toString()} ${(data['apellido'] ?? '')
                    .toString()}'
                    .trim();
            return DropdownMenuItem(
                value: d.id,
                child: Text(fullName
                        .isNotEmpty
                    ? fullName
                    : 'Veterinario'));
          }).toList();

          if (vetItems.isEmpty) {
            return _campoDeshabilitado(
                'Veterinario (Opcional)',
                'No hay veterinarios disponibles');
          }

          return Padding(
            padding:
                const EdgeInsets.symmetric(
                    vertical: 6),
            child: DropdownButtonFormField<
                String>(
              value:
                  veterinarioSeleccionadoId,
              isExpanded: true,
              decoration:
                  InputDecoration(
                labelText:
                    'Veterinario (Opcional)',
                labelStyle:
                    const TextStyle(
                        color: Colors.green),
                filled: true,
                fillColor:
                    Colors.white,
                border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(
                            12)),
              ),
              items:
                  vetItems,
              onChanged:
                  (val) {
                if (val == null)
                  return;
                final matched =
                    docsV.firstWhere(
                        (d) =>
                            d.id == val);
                final data =
                    matched.data()
                        as Map<String,
                            dynamic>;
                final fullName =
                    '${(data['nombre'] ?? '')
                        .toString()} ${(data['apellido'] ?? '')
                        .toString()}'
                        .trim();
                setState(() {
                  veterinarioSeleccionadoId =
                      val;
                  veterinarioSeleccionadoNombre =
                      fullName;
                });
              },
            ),
          );
        },
      );
    }
  }
