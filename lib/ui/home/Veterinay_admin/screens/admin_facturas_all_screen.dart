import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/admin_factura_card.dart';

class AdminFacturasAllScreen extends StatefulWidget {
  const AdminFacturasAllScreen({super.key});

  @override
  State<AdminFacturasAllScreen> createState() => _AdminFacturasAllScreenState();
}

class _AdminFacturasAllScreenState extends State<AdminFacturasAllScreen> {
  final Color green = const Color(0xFF388E3C);
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String filtro = "";
  String veterinariaId = "";
  bool cargando = true;
  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  void initState() {
    super.initState();
    // Set the veterinariaId to current user and stop initial loading
    veterinariaId = FirebaseAuth.instance.currentUser?.uid ?? '';
    cargando = false;
  }
  
  

  /// Stream con facturas por veterinaria
  Stream<List<Map<String, dynamic>>> _obtenerFacturasAdmin() {
    if (veterinariaId.isEmpty) return const Stream.empty();

    return _db
        .collection('facturas')
        .where('veterinariaId', isEqualTo: veterinariaId)
        .snapshots()
        .asyncMap((snapshot) async {
      // For each factura, fetch owner (cliente) data from users collection
      final futures = snapshot.docs.map((doc) async {
        final data = doc.data();

        // Fecha puede estar en 'fechaPago' o 'fecha' y en formatos Timestamp, DateTime o String
        DateTime fecha;
        final rawFecha = data['fechaPago'] ?? data['fecha'];
        if (rawFecha is Timestamp) {
          fecha = rawFecha.toDate();
        } else if (rawFecha is DateTime) {
          fecha = rawFecha;
        } else if (rawFecha is String) {
          try {
            fecha = DateTime.parse(rawFecha);
          } catch (_) {
            fecha = DateTime.now();
          }
        } else {
          fecha = DateTime.now();
        }

        final map = {
          ...data,
          'fecha': fecha,
          'id': doc.id,
        };

        // Try common owner id fields
        final duenoId = data['duenoId'] ?? data['clienteId'] ?? data['userId'];
        if (duenoId != null && duenoId.toString().isNotEmpty) {
          try {
            // First try the 'users' collection (used for staff/admin), then 'customers'
            DocumentSnapshot<Map<String, dynamic>>? userDoc;
            userDoc = await _db.collection('users').doc(duenoId.toString()).get();
            if (!userDoc.exists) {
              userDoc = await _db.collection('customers').doc(duenoId.toString()).get();
            }

            if (userDoc.exists) {
              final u = userDoc.data()!;
              // Build full name from possible fields
              final first = (u['nombre'] ?? u['firstName'] ?? '').toString();
              final last = (u['apellido'] ?? u['lastName'] ?? '').toString();
              String fullName = '';
              if (first.isNotEmpty && last.isNotEmpty) {
                fullName = '${first.trim()} ${last.trim()}';
              } else if (first.isNotEmpty) {
                fullName = first.trim();
              } else if (u['displayName'] != null) {
                fullName = u['displayName'].toString();
              }

              map['duenoNombre'] = fullName.isNotEmpty
                  ? fullName
                  : (data['duenoNombre'] ?? '').toString();

              // Try several possible fields for identification / document number
              final identificacion = (u['numeroDocumento'] ?? u['numero_doc'] ?? u['identificacion'] ?? u['cedula'] ?? u['documento'] ?? u['numeroDocumento'] ?? '').toString();
              map['duenoIdentificacion'] = identificacion.isNotEmpty
                  ? identificacion
                  : (data['duenoIdentificacion'] ?? '').toString();
            } else {
              map['duenoNombre'] = data['duenoNombre'] ?? '';
              map['duenoIdentificacion'] = data['duenoIdentificacion'] ?? '';
            }
          } catch (e) {
            // If fetching user fails, fallback to existing fields if present
            map['duenoNombre'] = data['duenoNombre'] ?? '';
            map['duenoIdentificacion'] = data['duenoIdentificacion'] ?? '';
          }
        } else {
          map['duenoNombre'] = data['duenoNombre'] ?? '';
          map['duenoIdentificacion'] = data['duenoIdentificacion'] ?? '';
        }

        // Additional fallbacks: some facturas store cliente info nested or under different keys
        if ((map['duenoNombre'] ?? '').toString().isEmpty) {
          // nested 'dueno' map
          if (data['dueno'] is Map) {
            final dm = Map<String, dynamic>.from(data['dueno']);
            final first = (dm['nombre'] ?? dm['firstName'] ?? dm['displayName'] ?? '').toString();
            final last = (dm['apellido'] ?? dm['lastName'] ?? '').toString();
            String fullName = '';
            if (first.isNotEmpty && last.isNotEmpty) {
              fullName = '${first.trim()} ${last.trim()}';
            } else if (first.isNotEmpty) {
              fullName = first.trim();
            } else if (dm['displayName'] != null) {
              fullName = dm['displayName'].toString();
            }
            if (fullName.isNotEmpty) map['duenoNombre'] = fullName;

            final idf = (dm['numeroDocumento'] ?? dm['numero_doc'] ?? dm['identificacion'] ?? dm['cedula'] ?? dm['documento'] ?? '').toString();
            if (idf.isNotEmpty) map['duenoIdentificacion'] = idf;
          }

          // nested 'cliente' map
          if ((map['duenoNombre'] ?? '').toString().isEmpty && data['cliente'] is Map) {
            final cm = Map<String, dynamic>.from(data['cliente']);
            final first = (cm['nombre'] ?? cm['firstName'] ?? cm['displayName'] ?? '').toString();
            final last = (cm['apellido'] ?? cm['lastName'] ?? '').toString();
            String fullName = '';
            if (first.isNotEmpty && last.isNotEmpty) {
              fullName = '${first.trim()} ${last.trim()}';
            } else if (first.isNotEmpty) {
              fullName = first.trim();
            } else if (cm['displayName'] != null) {
              fullName = cm['displayName'].toString();
            }
            if (fullName.isNotEmpty) map['duenoNombre'] = fullName;

            final idf = (cm['numeroDocumento'] ?? cm['numero_doc'] ?? cm['identificacion'] ?? cm['cedula'] ?? cm['documento'] ?? '').toString();
            if (idf.isNotEmpty) map['duenoIdentificacion'] = idf;
          }

          // invoice-level alternative fields
          if ((map['duenoNombre'] ?? '').toString().isEmpty) {
            final altName = (data['clienteNombre'] ?? data['clienteNombreCompleto'] ?? data['ownerName'] ?? data['owner'] ?? data['cliente_full_name'] ?? '').toString();
            if (altName.isNotEmpty) map['duenoNombre'] = altName;
          }

          if ((map['duenoIdentificacion'] ?? '').toString().isEmpty) {
            final altId = (data['clienteIdentificacion'] ?? data['cliente_documento'] ?? data['documento'] ?? data['identificacion'] ?? data['cedula'] ?? '').toString();
            if (altId.isNotEmpty) map['duenoIdentificacion'] = altId;
          }
        }

        return map;
      }).toList();

      final lista = await Future.wait(futures);

      lista.sort((a, b) => b['fecha'].compareTo(a['fecha']));

      // Apply date range filter if set
      List<Map<String, dynamic>> filteredByDate = lista;
      if (_fromDate != null || _toDate != null) {
        final from = _fromDate != null
            ? DateTime(_fromDate!.year, _fromDate!.month, _fromDate!.day)
            : DateTime.fromMillisecondsSinceEpoch(0);
        final to = _toDate != null
            ? DateTime(_toDate!.year, _toDate!.month, _toDate!.day, 23, 59, 59)
            : DateTime.now().add(const Duration(days: 36500));

        filteredByDate = lista.where((f) {
          final fecha = f['fecha'] as DateTime?;
          if (fecha == null) return false;
          return !fecha.isBefore(from) && !fecha.isAfter(to);
        }).toList();
      }

      final listaFinal = filteredByDate;

      if (filtro.isEmpty) return listaFinal;

      final texto = filtro.toLowerCase();

      return listaFinal.where((f) {
        final nombre = (f['duenoNombre'] ?? '').toString().toLowerCase();
        final servicio = (f['servicioNombre'] ?? '').toString().toLowerCase();
        final id = (f['id'] ?? '').toString().toLowerCase();
        final identificacion = (f['duenoIdentificacion'] ?? '').toString().toLowerCase();

        return nombre.contains(texto) || servicio.contains(texto) || id.contains(texto) || identificacion.contains(texto);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade50,
      appBar: AppBar(
        backgroundColor: green,
        title: const Text("Facturas de la Veterinaria"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildSearchBar(),
                  const SizedBox(height: 12),
                  _buildDateFilters(),
                  const SizedBox(height: 12),

                  Expanded(
                    child: StreamBuilder<List<Map<String, dynamic>>>(
                      stream: _obtenerFacturasAdmin(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final facturas = snapshot.data!;

                        if (facturas.isEmpty) {
                          return Center(
                            child: Text(
                              'No hay facturas registradas',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          );
                        }

                        return ListView.builder(
                          itemCount: facturas.length,
                          itemBuilder: (context, index) =>
                              AdminFacturaCard(factura: facturas[index]),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      onChanged: (value) => setState(() => filtro = value),
      decoration: InputDecoration(
        hintText: "Buscar por cliente, servicio o factura...",
        filled: true,
        fillColor: Colors.white,
        prefixIcon: Icon(Icons.search, color: green),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildDateFilters() {
    final Color green = const Color(0xFF388E3C);

    Future<void> pickFrom() async {
      final now = DateTime.now();
      final picked = await showDatePicker(
        context: context,
        initialDate: _fromDate ?? now,
        firstDate: DateTime(2000),
        lastDate: DateTime(now.year + 5),
      );
      if (picked != null) setState(() => _fromDate = picked);
    }

    Future<void> pickTo() async {
      final now = DateTime.now();
      final picked = await showDatePicker(
        context: context,
        initialDate: _toDate ?? _fromDate ?? now,
        firstDate: DateTime(2000),
        lastDate: DateTime(now.year + 5),
      );
      if (picked != null) setState(() => _toDate = picked);
    }

    String fmt(DateTime? d) => d == null ? 'Seleccionar' : '${d.day}/${d.month}/${d.year}';

    Widget dateButton({required String label, required String value, required VoidCallback onTap, required IconData icon}) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              Icon(icon, color: green, size: 18),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  '$label: $value',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  softWrap: false,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(builder: (context, constraints) {
      final isNarrow = constraints.maxWidth < 420;
      if (isNarrow) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            dateButton(label: 'Desde', value: fmt(_fromDate), onTap: pickFrom, icon: Icons.calendar_today),
            const SizedBox(height: 8),
            dateButton(label: 'Hasta', value: fmt(_toDate), onTap: pickTo, icon: Icons.calendar_today_outlined),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => setState(() { _fromDate = null; _toDate = null; }),
                child: const Text('Limpiar'),
              ),
            ),
          ],
        );
      }

      return Row(
        children: [
          Expanded(child: dateButton(label: 'Desde', value: fmt(_fromDate), onTap: pickFrom, icon: Icons.calendar_today)),
          const SizedBox(width: 8),
          Expanded(child: dateButton(label: 'Hasta', value: fmt(_toDate), onTap: pickTo, icon: Icons.calendar_today_outlined)),
          const SizedBox(width: 8),
          SizedBox(
            width: 72,
            child: TextButton(
              onPressed: () => setState(() { _fromDate = null; _toDate = null; }),
              child: const Text('Limpiar', overflow: TextOverflow.ellipsis),
            ),
          ),
        ],
      );
    });
  }
}