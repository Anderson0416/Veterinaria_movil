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

  final Color green = const Color(0xFF388E3C);
  final Color greenLight = const Color(0xFFE8F5E9);

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
    final facturaExistente =
        await facturaController.getFacturaPorCita(widget.cita.id!);

    if (facturaExistente != null) {
      Get.snackbar("Aviso", "La factura ya existe.", backgroundColor: green, colorText: Colors.white);
      generando = false;
      setState(() {});
      return;
    }
    await appointmentController.marcarComoPagada(widget.cita);
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
      Get.snackbar("Error", "No se pudo generar la factura", backgroundColor: Colors.red, colorText: Colors.white);
      generando = false;
      setState(() {});
      return;
    }

    Get.snackbar("Pago realizado", "La factura fue registrada exitosamente.", backgroundColor: green, colorText: Colors.white);
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
      backgroundColor: const Color(0xFFF0F8F5),
      appBar: AppBar(
        title: const Text("Pago de la Cita", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        backgroundColor: green,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: green,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.receipt_long, color: Colors.white, size: 28),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Resumen de Pago",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Cita: ${cita.id!.substring(0, 8)}...",
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  _buildInfoCard(
                    icon: Icons.person,
                    title: "Información del Cliente",
                    items: [
                      _buildInfoItem("Nombre", dueno?.nombre ?? "No encontrado"),
                      _buildInfoItem("Documento", dueno?.numeroDocumento ?? "No disponible"),
                      _buildInfoItem("Teléfono", dueno?.telefono ?? "No disponible"),
                    ],
                  ),

                  const SizedBox(height: 16),
                  _buildInfoCard(
                    icon: Icons.calendar_today,
                    title: "Información de la Cita",
                    items: [
                      _buildInfoItem("Veterinaria", veterinaria?.nombre ?? "No encontrada"),
                      _buildInfoItem("Servicio", servicio?.nombre ?? "No encontrado"),
                      _buildInfoItem("Fecha", "${cita.fecha.day}/${cita.fecha.month}/${cita.fecha.year}"),
                      _buildInfoItem("Hora", cita.hora),
                    ],
                  ),

                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [green, green.withOpacity(0.8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Total a Pagar",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "\$${(servicio?.precio ?? 0).toStringAsFixed(2)}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 1,
                          color: Colors.white.withOpacity(0.3),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Concepto: Servicio Veterinario",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: generando ? null : () => Get.back(),
                          icon: const Icon(Icons.close),
                          label: const Text("Cancelar"),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: green,
                            side: BorderSide(color: green, width: 1.5),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: generando ? null : pagarFactura,
                          icon: Icon(
                            generando ? Icons.hourglass_bottom : Icons.payment,
                          ),
                          label: Text(
                            generando ? "Procesando..." : "Pagar Ahora",
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            disabledBackgroundColor: Colors.grey.shade400,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required List<Widget> items,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: green.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: greenLight,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: green, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...items,
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}
