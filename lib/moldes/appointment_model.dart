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
  });

  // Convertir a JSON para Firestore
  Map<String, dynamic> toJson() {
    return {
      'duenoId': duenoId,
      'mascotaId': mascotaId,
      'veterinariaId': veterinariaId,
      'veterinarioId': veterinarioId,
      'servicioId': servicioId,
      'precioServicio': precioServicio,
      'fecha': fecha.toIso8601String(),
      'hora': hora,
      'direccion': direccion,
      'latitud': latitud,
      'longitud': longitud,
      'estado': estado,
      'pagado': pagado,
      'observaciones': observaciones, 
    };
  }

  // Convertir desde Firestore
  factory CitaModel.fromJson(Map<String, dynamic> json, String id) {
    return CitaModel(
      id: id,
      duenoId: json['duenoId'],
      mascotaId: json['mascotaId'],
      veterinariaId: json['veterinariaId'],
      veterinarioId: json['veterinarioId'],
      servicioId: json['servicioId'],
      precioServicio: (json['precioServicio'] as num).toDouble(),
      fecha: DateTime.parse(json['fecha']),
      hora: json['hora'],
      direccion: json['direccion'],
      latitud: (json['latitud'] as num).toDouble(),
      longitud: (json['longitud'] as num).toDouble(),
      estado: json['estado'] ?? 'pendiente',
      pagado: json['pagado'] ?? false,
      observaciones: json['observaciones'] ?? "", 
    );
  }
}
