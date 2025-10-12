import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:veterinaria_movil/controllers/customer_controller.dart';


//widgets
import 'package:veterinaria_movil/ui/home/customer_interface/widgets/customer_action_buttons.dart';
import 'package:veterinaria_movil/ui/home/customer_interface/widgets/customer_appointments_card.dart';
import 'package:veterinaria_movil/ui/home/customer_interface/widgets/customer_header.dart';
import 'package:veterinaria_movil/ui/home/customer_interface/widgets/customer_pets_card.dart';
import 'package:veterinaria_movil/ui/home/customer_interface/widgets/customer_profile_dialog.dart';

class CustomerMenuScreen extends StatefulWidget {
  const CustomerMenuScreen({super.key});

  @override
  State<CustomerMenuScreen> createState() => _CustomerMenuScreenState();
}

class _CustomerMenuScreenState extends State<CustomerMenuScreen> {
  String? userName; // nombre del cliente
  String? userId;

  @override
  void initState() {
    super.initState();
    _loadCustomerData();
  }

  Future<void> _loadCustomerData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('customers')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        setState(() {
          userName = doc.data()?['nombre'] ?? 'Cliente';
          userId = user.uid;
        });
      }
    } catch (e) {
      debugPrint("Error al cargar nombre del cliente: $e");
    }
  }

  Future<void> _showCustomerData(BuildContext context) async {
    try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Get.snackbar("Error", "No hay sesión iniciada");
      return;
    }

    final customer = await CustomerController().getCustomerById(user.uid);
    if (customer == null) {
      Get.snackbar("Sin datos", "No se encontró información del cliente");
      return;
    }

    Get.dialog(CustomerProfileDialog(customer: customer));
  } catch (e) {
    Get.snackbar("Error", "Ocurrió un problema: $e");
  }
  }

  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade50,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              CustomerHeader(
                userName: userName ?? "Cliente",
                onProfileTap: () => _showCustomerData(context),
              ),
              const SizedBox(height: 16),
              const CustomerActionButtons(),
              const SizedBox(height: 20),
              const CustomerAppointmentsCard(),
              const SizedBox(height: 20),
              const CustomerPetsCard(),
            ],
          ),
        ),
      ),
    );
  }
}
