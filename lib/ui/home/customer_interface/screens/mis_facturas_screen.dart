import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:veterinaria_movil/moldes/factura_model.dart';
import '../widgets/factura_card.dart';

class MisFacturasScreen extends StatefulWidget {
  const MisFacturasScreen({super.key});

  @override
  State<MisFacturasScreen> createState() => _MisFacturasScreenState();
}

class _MisFacturasScreenState extends State<MisFacturasScreen> {
  final Color green = const Color(0xFF388E3C);
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String filtro = "";

  Stream<List<FacturaModel>> _obtenerFacturas() {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    return _db
        .collection('facturas')
        .where('duenoId', isEqualTo: userId)
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade50,
      appBar: AppBar(
        backgroundColor: green,
        title: const Text("Todas las Facturas"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSearchBar(),
            const SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<List<FacturaModel>>(
                stream: _obtenerFacturas(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final facturas = snapshot.data ?? [];

                  if (facturas.isEmpty) {
                    return Center(
                      child: Text(
                        'No hay facturas que coincidan',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: facturas.length,
                    itemBuilder: (context, index) =>
                        FacturaCard(factura: facturas[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // BUSCADOR
  Widget _buildSearchBar() {
    return TextField(
      onChanged: (value) => setState(() => filtro = value),
      decoration: InputDecoration(
        hintText: "Buscar por servicio o número de factura...",
        filled: true,
        fillColor: Colors.white,
        prefixIcon: Icon(Icons.search, color: green),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.green.shade200),
        ),
      ),
    );
  }
}
