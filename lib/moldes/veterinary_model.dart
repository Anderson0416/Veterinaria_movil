// lib/moldes/veterinary_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class VeterinaryModel {
  String? id;
  String nombre;
  String direccion;
  String telefono;
  String nit;
  String correo;
  String? departamento;
  String? ciudad;
  String? horarioLV;
  String? horarioSab;
  bool activo;
  GeoPoint? ubicacion;
  double? latitud;
  double? longitud;

  VeterinaryModel({
    this.id,
    required this.nombre,
    required this.direccion,
    required this.telefono,
    required this.nit,
    required this.correo,
    this.departamento,
    this.ciudad,
    this.horarioLV,
    this.horarioSab,
    this.activo = true,
    this.ubicacion,
    this.latitud,
    this.longitud,
  });

  /// Convierte el modelo a Map para Firestore
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'nombre': nombre,
      'direccion': direccion,
      'telefono': telefono,
      'nit': nit,
      'correo': correo,
      'departamento': departamento,
      'ciudad': ciudad,
      'horarioLV': horarioLV,
      'horarioSab': horarioSab,
      'activo': activo,
      // guardamos lat/lng separados (útil para consultas geográficas simples)
      'latitud': latitud,
      'longitud': longitud,
    };

    // Si hay GeoPoint lo guardamos también (opcional)
    if (ubicacion != null) {
      map['ubicacion'] = ubicacion;
    } else if (latitud != null && longitud != null) {
      // si no hay GeoPoint pero sí lat/lng, guardamos GeoPoint para compatibilidad
      map['ubicacion'] = GeoPoint(latitud!, longitud!);
    }

    return map;
  }

  /// Crea instancia a partir de un doc (maneja GeoPoint o lat/lng)
  factory VeterinaryModel.fromMap(Map<String, dynamic> map, String id) {
    // leer ubicacion si viene como GeoPoint
    GeoPoint? gp;
    double? lat;
    double? lng;

    if (map['ubicacion'] is GeoPoint) {
      gp = map['ubicacion'] as GeoPoint;
      lat = gp.latitude;
      lng = gp.longitude;
    } else {
      // fallback a campos latitud/longitud separados
      final dynamic maybeLat = map['latitud'];
      final dynamic maybeLng = map['longitud'];
      if (maybeLat is num && maybeLng is num) {
        lat = maybeLat.toDouble();
        lng = maybeLng.toDouble();
        gp = GeoPoint(lat, lng);
      }
    }

    return VeterinaryModel(
      id: id,
      nombre: map['nombre'] ?? '',
      direccion: map['direccion'] ?? '',
      telefono: map['telefono'] ?? '',
      nit: map['nit'] ?? '',
      correo: map['correo'] ?? '',
      departamento: map['departamento'],
      ciudad: map['ciudad'],
      horarioLV: map['horarioLV'],
      horarioSab: map['horarioSab'],
      activo: map['activo'] ?? true,
      ubicacion: gp,
      latitud: lat,
      longitud: lng,
    );
  }

  /// copyWith para actualizar campos puntuales
  VeterinaryModel copyWith({
    String? id,
    String? nombre,
    String? direccion,
    String? telefono,
    String? nit,
    String? correo,
    String? departamento,
    String? ciudad,
    String? horarioLV,
    String? horarioSab,
    bool? activo,
    GeoPoint? ubicacion,
    double? latitud,
    double? longitud,
  }) {
    return VeterinaryModel(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      direccion: direccion ?? this.direccion,
      telefono: telefono ?? this.telefono,
      nit: nit ?? this.nit,
      correo: correo ?? this.correo,
      departamento: departamento ?? this.departamento,
      ciudad: ciudad ?? this.ciudad,
      horarioLV: horarioLV ?? this.horarioLV,
      horarioSab: horarioSab ?? this.horarioSab,
      activo: activo ?? this.activo,
      ubicacion: ubicacion ?? this.ubicacion,
      latitud: latitud ?? this.latitud,
      longitud: longitud ?? this.longitud,
    );
  }

  /// 🔹 Genera el enlace directo de Google Maps con las coordenadas
  String? getGoogleMapsUrl() {
    if (latitud != null && longitud != null) {
      return "https://www.google.com/maps?q=$latitud,$longitud";
    }
    return null;
  }
}
