import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:veterinaria_movil/controllers/animal_type_controller.dart';
import 'package:veterinaria_movil/controllers/appointment_controllers.dart';
import 'package:veterinaria_movil/controllers/breed_controller.dart';
import 'package:veterinaria_movil/controllers/pet_controller.dart';
import 'package:veterinaria_movil/controllers/veterinarian_controller.dart';
import 'package:veterinaria_movil/controllers/add_user_controllers.dart';
import 'package:veterinaria_movil/controllers/customer_controller.dart';
import 'package:veterinaria_movil/controllers/veterinary_controller.dart';
import 'package:veterinaria_movil/firebase_options.dart';
import 'package:veterinaria_movil/ui/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
);

  Get.put(AddUserControllers());
  Get.put(CustomerController());
  Get.put(VeterinaryController());
  Get.put(VeterinarianController());
  Get.put(PetController());
  Get.put(AnimalTypeController());
  Get.put(BreedController());
  Get.put(AppointmentController());
  runApp(const MyApp());
}

