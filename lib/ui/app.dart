import 'package:flutter/material.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:veterinaria_movil/ui/home/login_screens.dart';
import 'package:veterinaria_movil/ui/home/register_customer_screen.dart';
import 'package:veterinaria_movil/ui/home/register_veterinary_screen.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Veterinaria',
      home: RegisterCustomerScreen(), 
    );
  }
}
