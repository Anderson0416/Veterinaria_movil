import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:veterinaria_movil/controllers/customer_controller.dart';
import 'package:veterinaria_movil/controllers/veterinary_controller.dart';
import 'package:veterinaria_movil/controllers/service_controller.dart';
import 'package:veterinaria_movil/controllers/appointment_controllers.dart';
import 'package:veterinaria_movil/controllers/factura_controllers.dart';

import 'package:veterinaria_movil/moldes/appointment_model.dart';
import 'package:veterinaria_movil/moldes/customer_model.dart';
import 'package:veterinaria_movil/moldes/veterinary_model.dart';
import 'package:veterinaria_movil/moldes/service_model.dart';
import 'package:veterinaria_movil/moldes/factura_model.dart';

class FacturaScreen extends StatefulWidget {
  final CitaModel cita;

  const FacturaScreen({super.key, required this.cita});

  @override
  State<FacturaScreen> createState() => _FacturaScreenState();
}

class _FacturaScreenState extends State<FacturaScreen> {
  final appointmentController = Get.put(AppointmentController());
  final facturaController = Get.put(FacturaController());
  final customerController = Get.put(CustomerController());
  final veterinaryController = Get.put(VeterinaryController());
  final serviceController = Get.put(ServiceController());

  Customer? dueno;
  VeterinaryModel? veterinaria;
  ServiceModel? servicio;

  bool cargando = true;
  final correoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    cargarDatos();
  }

  Future<void> cargarDatos() async {
    dueno = await customerController.getCustomerById(widget.cita.duenoId);
    veterinaria =
        await veterinaryController.getVeterinaryById(widget.cita.veterinariaId);
    servicio = await serviceController.getServiceById(widget.cita.servicioId);

    setState(() => cargando = false);
  }

  Future<void> generarYEnviarFactura() async {
    if (correoController.text.isEmpty) {
      Get.snackbar("Error", "Ingrese un correo válido");
      return;
    }

    // 1. Verificar si YA existe una factura
    final facturaExistente =
        await facturaController.getFacturaPorCita(widget.cita.id!);

    if (facturaExistente != null) {
      Get.snackbar("Aviso", "La factura ya existe.");
      return;
    }

    // 2. Marcar cita como pagada
    await appointmentController.marcarComoPagada(widget.cita);

    // 3. Crear factura
    final factura = FacturaModel(
      citaId: widget.cita.id!,
      duenoId: widget.cita.duenoId,
      veterinariaId: widget.cita.veterinariaId,
      servicioId: widget.cita.servicioId,
      servicioNombre: servicio?.nombre ?? "",
      total: servicio?.precio ?? 0,
      fechaPago: DateTime.now(),
    );

    final facturaId = await facturaController.crearFactura(factura);
    final facturaCompleta = await facturaController.getFactura(facturaId);

    if (facturaCompleta == null) {
      Get.snackbar("Error", "No se pudo generar la factura");
      return;
    }

    // 4. ENVIAR PDF
    await facturaController.enviarFacturaPorCorreo(
      factura: facturaCompleta,
      correoCliente: correoController.text.trim(),
      dueno: dueno!,
      veterinaria: veterinaria!,
      servicio: servicio!,
    );

    Get.snackbar("Factura enviada", "Se envió correctamente.");

    // 5. Regresar
    Future.delayed(const Duration(milliseconds: 600), () {
      Get.offAllNamed('/vetAppointments');
    });
  }

  @override
  Widget build(BuildContext context) {
    final cita = widget.cita;

    return Scaffold(
      appBar: AppBar(
          title: const Text("Factura de la cita"),
          backgroundColor: Colors.teal),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(15),
              child: ListView(
                children: [
                  Text("Detalle de la cita",
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),

                  Text("Código de la cita: ${cita.id}"),

                  Text("Dueño: ${dueno?.nombre ?? 'No encontrado'}"),
                  Text("Documento: ${dueno?.numeroDocumento ?? ''}"),

                  Text("Veterinaria: ${veterinaria?.nombre ?? 'No encontrada'}"),

                  Text("Servicio: ${servicio?.nombre ?? 'No encontrado'}"),

                  const SizedBox(height: 15),

                  Text("Precio:",
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text("\$${(servicio?.precio ?? 0).toStringAsFixed(2)}",
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold)),

                  const SizedBox(height: 25),

                  const Text("Correo del cliente"),
                  TextField(
                    controller: correoController,
                    decoration: const InputDecoration(
                        hintText: "cliente@correo.com"),
                  ),

                  const SizedBox(height: 40),

                  ElevatedButton.icon(
                    onPressed: generarYEnviarFactura,
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text("Generar y Enviar Factura"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 25, vertical: 15),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
