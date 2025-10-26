import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  // ✅ Crear automáticamente las colecciones de tipos y razas si no existen
  await _initializeAnimalData();

  runApp(const MyApp());
}

Future<void> _initializeAnimalData() async {
  final firestore = FirebaseFirestore.instance;
  final typesCollection = firestore.collection('animal_types');
  final breedsCollection = firestore.collection('breeds');

  // Lista de tipos de animales
  final animalTypes = [
    'Perro',
    'Gato',
    'Vaca',
    'Ave',
    'Caballo',
    'Conejo',
    'Cerdo',
  ];

  // Revisar si ya existen
  final existing = await typesCollection.get();
  if (existing.docs.isNotEmpty) return; // Ya existen, no los crea otra vez

  // Guardar IDs creados
  final Map<String, String> typeIds = {};

  // Crear tipos
  for (final type in animalTypes) {
    final doc = await typesCollection.add({'nombre': type});
    typeIds[type] = doc.id;
  }

  // Crear razas según tipo
  final breedsData = {
    'Perro': [
      'Labrador Retriever',
      'Bulldog',
      'Poodle',
      'Golden Retriever',
      'Beagle',
      'Chihuahua',
      'Boxer',
      'Dálmata',
      'Pastor Alemán',
      'Rottweiler',
      'Desconocido'
    ],
    'Gato': [
      'Persa',
      'Siamés',
      'Maine Coon',
      'Bengalí',
      'Esfinge',
      'British Shorthair',
      'Ragdoll',
      'Abisinio',
      'Bombay',
      'Azul Ruso',
      'Desconocido'
    ],
    'Vaca': [
      'Holstein',
      'Jersey',
      'Angus',
      'Desconocido'
    ],
    'Ave': [
      'Canario',
      'Loro',
      'Gallina',
      'Desconocido'
    ],
    'Caballo': [
      'Árabe',
      'Pura Sangre',
      'Criollo',
      'Desconocido'
    ],
    'Conejo': [
      'Belier',
      'Angora',
      'Rex',
      'Desconocido'
    ],
    'Cerdo': [
      'Yorkshire',
      'Landrace',
      'Duroc',
      'Desconocido'
    ],
  };

  // Insertar razas con relación al tipo
  for (final entry in breedsData.entries) {
    final typeName = entry.key;
    final typeId = typeIds[typeName];
    for (final breed in entry.value) {
      await breedsCollection.add({
        'nombre': breed,
        'animalTypeId': typeId, // Relación con el tipo
      });
    }
  }

  print('✅ Colecciones de tipos y razas creadas correctamente.');
}
