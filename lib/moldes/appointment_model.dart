import 'package:cloud_firestore/cloud_firestore.dart';

class CitaModel {
  String? id;
  String duenoId;           
  String mascotaId;         
  String veterinariaId;      
  String veterinarioId;      
  String servicioId;         
  double precioServicio;     
  DateTime fecha;          
  String hora;              
  String direccion;          
  double latitud;            
  double longitud;
  String estado;            
  bool pagado;  
  String observaciones;
  String modalidad; 

  CitaModel({
    this.id,
    required this.duenoId,
    required this.mascotaId,
    required this.veterinariaId,
    required this.veterinarioId,
    required this.servicioId,
    required this.precioServicio,
    required this.fecha,
    required this.hora,
    required this.direccion,
    required this.latitud,
    required this.longitud,
    required this.estado,
    required this.pagado,
    required this.observaciones,
    required this.modalidad,
  });

  Map<String, dynamic> toJson() {
    return {
      'duenoId': duenoId,
      'mascotaId': mascotaId,
      'veterinariaId': veterinariaId,
      'veterinarioId': veterinarioId,
      'servicioId': servicioId,
      'precioServicio': precioServicio,
      'fecha': Timestamp.fromDate(fecha),
      'hora': hora,
      'direccion': direccion,
      'latitud': latitud,
      'longitud': longitud,
      'estado': estado,
      'pagado': pagado,
      'observaciones': observaciones,
      'modalidad': modalidad,
    };
  }

  factory CitaModel.fromJson(Map<String, dynamic> json, String id) {
    DateTime parsedFecha;

    if (json['fecha'] is Timestamp) {
      parsedFecha = (json['fecha'] as Timestamp).toDate();
    } else if (json['fecha'] is String) {
      parsedFecha = DateTime.parse(json['fecha']);
    } else {
      parsedFecha = DateTime.now();
    }

    return CitaModel(
      id: id,
      duenoId: json['duenoId'] ?? '',
      mascotaId: json['mascotaId'] ?? '',
      veterinariaId: json['veterinariaId'] ?? '',
      veterinarioId: json['veterinarioId'] ?? '',
      servicioId: json['servicioId'] ?? '',
      precioServicio: (json['precioServicio'] as num?)?.toDouble() ?? 0.0,
      fecha: parsedFecha,
      hora: json['hora'] ?? '',
      direccion: json['direccion'] ?? '',
      latitud: (json['latitud'] as num?)?.toDouble() ?? 0.0,
      longitud: (json['longitud'] as num?)?.toDouble() ?? 0.0,
      estado: json['estado'] ?? 'pendiente',
      pagado: json['pagado'] ?? false,
      observaciones: json['observaciones'] ?? '',
      modalidad: json['modalidad'] ?? "presencial",
    );
  }
}
