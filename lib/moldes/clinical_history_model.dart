import 'package:cloud_firestore/cloud_firestore.dart';

class ClinicalHistoryModel {
  String? id;
  String citaId;
  String mascotaId;
  String mascotaNombre;
  String duenoId;
  String veterinarioId;
  String veterinariaId;
  DateTime fecha;
  double peso;
  double temperatura;
  int frecuenciaCardiaca;
  String motivoConsulta;
  String estadoGeneral;
  String observacionesExamen;
  String diagnostico;
  String tratamiento;
  DateTime? proximaCita;

  ClinicalHistoryModel({
    this.id,
    required this.citaId,
    required this.mascotaId,
    required this.mascotaNombre,
    required this.duenoId,
    required this.veterinarioId,
    required this.veterinariaId,
    required this.fecha,
    required this.peso,
    required this.temperatura,
    required this.frecuenciaCardiaca,
    required this.motivoConsulta,
    required this.estadoGeneral,
    required this.observacionesExamen,
    required this.diagnostico,
    required this.tratamiento,
    this.proximaCita,
  });

  // --- Mapeo a Firestore (Guardar) ---
  Map<String, dynamic> toJson() {
    return {
      'citaId': citaId,
      'mascotaId': mascotaId,
      'mascotaNombre': mascotaNombre,
      'duenoId': duenoId,
      'veterinarioId': veterinarioId,
      'veterinariaId': veterinariaId,
      'fecha': Timestamp.fromDate(fecha),
      'peso': peso,
      'temperatura': temperatura,
      'frecuenciaCardiaca': frecuenciaCardiaca,
      'motivoConsulta': motivoConsulta,
      'estadoGeneral': estadoGeneral,
      'observacionesExamen': observacionesExamen,
      'diagnostico': diagnostico,
      'tratamiento': tratamiento,
      'proximaCita': proximaCita != null ? Timestamp.fromDate(proximaCita!) : null,
    };
  }

  // --- Mapeo desde JSON (Usualmente para APIs REST) ---
  factory ClinicalHistoryModel.fromJson(Map<String, dynamic> json, String id) {
    return _historyModelFromMap(json, id);
  }

  // 🌟 CONSTRUCTOR CORREGIDO 🌟
  // Este constructor de fábrica resuelve el error de "Member not found" en tu lógica de lectura de Firestore.
  // Permite usar .fromMap en tu controlador/pantalla.
  factory ClinicalHistoryModel.fromMap(Map<String, dynamic> json, String id) {
    return _historyModelFromMap(json, id);
  }
}

// Función auxiliar para evitar la duplicación de lógica de deserialización.
ClinicalHistoryModel _historyModelFromMap(Map<String, dynamic> json, String id) {
  // Manejo de 'fecha' (Timestamp de Firestore)
  DateTime parsedFecha;
  if (json['fecha'] is Timestamp) {
    parsedFecha = (json['fecha'] as Timestamp).toDate();
  } else if (json['fecha'] is String) {
    parsedFecha = DateTime.parse(json['fecha']);
  } else {
    // Proporcionar un valor predeterminado seguro
    parsedFecha = DateTime.now(); 
  }

  // Manejo de 'proximaCita' (Timestamp de Firestore o null)
  DateTime? parsedProximaCita;
  if (json['proximaCita'] != null) {
    if (json['proximaCita'] is Timestamp) {
      parsedProximaCita = (json['proximaCita'] as Timestamp).toDate();
    } else if (json['proximaCita'] is String) {
      parsedProximaCita = DateTime.parse(json['proximaCita']);
    }
  }

  return ClinicalHistoryModel(
    id: id,
    citaId: json['citaId'] ?? '',
    mascotaId: json['mascotaId'] ?? '',
    mascotaNombre: json['mascotaNombre'] ?? '',
    duenoId: json['duenoId'] ?? '',
    veterinarioId: json['veterinarioId'] ?? '',
    veterinariaId: json['veterinariaId'] ?? '',
    fecha: parsedFecha,
    // Se asegura de que se convierta a double, maneja tanto int como double desde num
    peso: (json['peso'] as num?)?.toDouble() ?? 0.0, 
    temperatura: (json['temperatura'] as num?)?.toDouble() ?? 0.0,
    // Se asegura de que se convierta a int, maneja num
    frecuenciaCardiaca: (json['frecuenciaCardiaca'] as num?)?.toInt() ?? 0, 
    motivoConsulta: json['motivoConsulta'] ?? '',
    estadoGeneral: json['estadoGeneral'] ?? '',
    observacionesExamen: json['observacionesExamen'] ?? '',
    diagnostico: json['diagnostico'] ?? '',
    tratamiento: json['tratamiento'] ?? '',
    proximaCita: parsedProximaCita,
  );
}