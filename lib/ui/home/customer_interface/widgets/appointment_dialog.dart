
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:veterinaria_movil/moldes/appointment_model.dart';
import 'package:veterinaria_movil/controllers/appointment_controllers.dart';

class AppointmentDialog {
  static void showDetails({
    required BuildContext context,
    required CitaModel cita,
    required Map<String, String> datos,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => _DetailsContent(
        cita: cita,
        datos: datos,
      ),
    );
  }
}

class _DetailsContent extends StatelessWidget {
  final CitaModel cita;
  final Map<String, String> datos;
  final AppointmentController controller = Get.find();

  _DetailsContent({required this.cita, required this.datos});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 20),

          const Text(
            "Detalles de la cita",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7D32),
            ),
          ),

          const SizedBox(height: 20),

          _infoRow("Mascota", datos['mascota']!),
          _divider(),
          _infoRow("Servicio", datos['servicio']!),
          _divider(),
          _infoRow("Fecha", datos['fecha']!),
          _divider(),
          _infoRow("Hora", datos['hora']!),
          _divider(),
          _infoRow("Dirección", cita.direccion),
          _divider(),
          _infoRow("Observaciones",
              cita.observaciones.isEmpty ? "Sin observaciones" : cita.observaciones),
          _divider(),
          _infoRow("Estado", cita.estado),

          const SizedBox(height: 30),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _whiteButton(
                text: "Cerrar",
                onPressed: () => Navigator.pop(context),
              ),
              _editButton(context),
              _deleteButton(context),
            ],
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Container(
        height: 1,
        color: Colors.grey.shade300,
      ),
    );
  }

  Widget _infoRow(String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
            width: 110,
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            )),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
  Widget _whiteButton({required String text, required VoidCallback onPressed}) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        side: BorderSide(color: Colors.grey.shade400),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(text, style: const TextStyle(color: Colors.black87)),
    );
  }

  Widget _editButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        Navigator.pop(context);
        _showEditForm(context);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFF57C00),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: const Text("Modificar"),
    );
  }

  Widget _deleteButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () => _confirmDelete(context),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: const Text("Eliminar"),
    );
  }
  void _confirmDelete(BuildContext context) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        "¿Seguro que quiere eliminar la cita?",
        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
      ),
      content: const Text(
        "La cita se eliminará por completo.",
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("No"),
        ),
        ElevatedButton(
          onPressed: () async {
            await controller.actualizarEstado(cita.id!, "Cancelada");

            Navigator.pop(context); 
            Navigator.pop(context); 

            Get.snackbar("Cita cancelada",
                "El estado de la cita fue eliminada");
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text("Sí, cancelar"),
        ),
      ],
    ),
  );
}


  void _showEditForm(BuildContext context) {
    DateTime fecha = cita.fecha;
    TimeOfDay hora = TimeOfDay.fromDateTime(cita.fecha);

    final fechaCtrl = TextEditingController(
        text: "${fecha.day}/${fecha.month}/${fecha.year}");
    final horaCtrl = TextEditingController(
        text: "${hora.hour.toString().padLeft(2, '0')}:${hora.minute.toString().padLeft(2, '0')}");

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) {
        return StatefulBuilder(builder: (context, setState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 25,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                const Text(
                  "Editar cita",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                const SizedBox(height: 25),

                _readonlyBox("Mascota", datos['mascota']!),
                _readonlyBox("Servicio", datos['servicio']!),
                const SizedBox(height: 20),

                _datePickerField(
                    context, "Fecha", fechaCtrl, fecha, (picked) {
                  setState(() {
                    fecha = picked;
                    fechaCtrl.text =
                        "${picked.day}/${picked.month}/${picked.year}";
                  });
                }),

                const SizedBox(height: 15),

                _timePickerField(
                    context, "Hora", horaCtrl, hora, (picked) {
                  setState(() {
                    hora = picked;
                    horaCtrl.text =
                        "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
                  });
                }),

                const SizedBox(height: 30),

                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () async {
                      final fechaActualizada = DateTime(
                        fecha.year,
                        fecha.month,
                        fecha.day,
                        hora.hour,
                        hora.minute,
                      );

                      await controller.actualizarCita(cita.id!, {
                        "fecha": fechaActualizada.toIso8601String(),
                        "hora": horaCtrl.text,
                      });

                      Navigator.pop(context);
                      Get.snackbar("Éxito", "Cita actualizada");
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 22, vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("Guardar cambios"),
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }
  Widget _readonlyBox(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: Color(0xFF2E7D32), fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            value,
            style: const TextStyle(fontSize: 15),
          ),
        ),
        const SizedBox(height: 15),
      ],
    );
  }

  Widget _datePickerField(BuildContext context, String label,
      TextEditingController ctrl, DateTime fecha, Function(DateTime) onPick) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: fecha,
          firstDate: DateTime.now(),
          lastDate: DateTime(DateTime.now().year + 2),
        );
        if (picked != null) onPick(picked);
      },
      child: _readonlyBox(label, ctrl.text),
    );
  }

  Widget _timePickerField(BuildContext context, String label,
      TextEditingController ctrl, TimeOfDay hora, Function(TimeOfDay) onPick) {
    return GestureDetector(
      onTap: () async {
        final picked =
            await showTimePicker(context: context, initialTime: hora);
        if (picked != null) onPick(picked);
      },
      child: _readonlyBox(label, ctrl.text),
    );
  }
}
