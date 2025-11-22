import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:veterinaria_movil/moldes/factura_model.dart';
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

  @override
  void initState() {
    super.initState();
    _obtenerFacturasVeterinaria();
  }
  
  Stream<List<FacturaModel>> _obtenerFacturasVeterinaria() {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    return _db
        .collection('facturas')
        .where('veterinariaId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final lista = snapshot.docs
          .map((doc) => FacturaModel.fromJson(doc.data(), doc.id))
          .toList();

      lista.sort((a, b) => b.fechaPago.compareTo(a.fechaPago));

      if (filtro.isEmpty) return lista;

      return lista
          .where((f) =>
              f.servicioNombre.toLowerCase().contains(filtro.toLowerCase()) ||
              f.id!.contains(filtro))
          .toList();
    });
      }

  /// 🔥 Stream con facturas por veterinaria
  Stream<List<Map<String, dynamic>>> _obtenerFacturasAdmin() {
    if (veterinariaId.isEmpty) return const Stream.empty();

    return _db
        .collection('facturas')
        .where('veterinariaId', isEqualTo: veterinariaId)
        .snapshots()
        .map((snapshot) {
      final lista = snapshot.docs.map((doc) {
        final data = doc.data();

        DateTime fecha = data['fecha'] is Timestamp
            ? (data['fecha'] as Timestamp).toDate()
            : (data['fecha'] as DateTime);

        return {
          ...data,
          "fecha": fecha,
          "id": doc.id,
        };
      }).toList();

      lista.sort((a, b) => b['fecha'].compareTo(a['fecha']));

      if (filtro.isEmpty) return lista;

      final texto = filtro.toLowerCase();

      return lista.where((f) {
        return f['duenoNombre'].toLowerCase().contains(texto) ||
            f['servicioNombre'].toLowerCase().contains(texto) ||
            f['id'].toLowerCase().contains(texto);
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
                  const SizedBox(height: 20),

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
}
