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
  final appointmentController = Get.find<AppointmentController>();
  final facturaController = Get.find<FacturaController>();
  final customerController = Get.find<CustomerController>();
  final veterinaryController = Get.find<VeterinaryController>();
  final serviceController = Get.find<ServiceController>();

  Customer? dueno;
  VeterinaryModel? veterinaria;
  ServiceModel? servicio;

  bool cargando = true;
  bool generando = false;

  @override
  void initState() {
    super.initState();
    cargarDatos();
  }

  Future<void> cargarDatos() async {
    dueno = await customerController.getCustomerById(widget.cita.duenoId);
    veterinaria = await veterinaryController.getVeterinaryById(widget.cita.veterinariaId);
    servicio = await serviceController.getServiceById(widget.cita.servicioId);

    setState(() => cargando = false);
  }

  Future<void> pagarFactura() async {
    if (generando) return;

    generando = true;
    setState(() {});

    /// 1️⃣ Verificar si ya existe factura
    final facturaExistente =
        await facturaController.getFacturaPorCita(widget.cita.id!);

    if (facturaExistente != null) {
      Get.snackbar("Aviso", "La factura ya existe.");
      generando = false;
      setState(() {});
      return;
    }

    /// 2️⃣ Marcar cita como pagada
    await appointmentController.marcarComoPagada(widget.cita);

    /// 3️⃣ Crear la factura
    final factura = FacturaModel(
      citaId: widget.cita.id!,
      duenoId: widget.cita.duenoId,
      veterinariaId: widget.cita.veterinariaId,
      servicioId: widget.cita.servicioId,
      servicioNombre: servicio?.nombre ?? "Desconocido",
      total: servicio?.precio ?? 0,
      fechaPago: DateTime.now(),
    );

    final facturaId = await facturaController.crearFactura(factura);

    final facturaCompleta = await facturaController.getFactura(facturaId);

    if (facturaCompleta == null) {
      Get.snackbar("Error", "No se pudo generar la factura");
      generando = false;
      setState(() {});
      return;
    }

    Get.snackbar("Pago realizado", "La factura fue registrada exitosamente.");

    /// 4️⃣ Regresar
    Future.delayed(const Duration(milliseconds: 600), () {
      Get.offAllNamed('/vetAppointments');
    });

    generando = false;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final cita = widget.cita;

    return Scaffold(
      appBar: AppBar(
          title: const Text("Pago de la cita"), backgroundColor: Colors.teal),
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
                  Text(
                    "\$${(servicio?.precio ?? 0).toStringAsFixed(2)}",
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 40),

                  ElevatedButton.icon(
                    onPressed: generando ? null : pagarFactura,
                    icon: const Icon(Icons.payment),
                    label: const Text("Pagar"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
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
