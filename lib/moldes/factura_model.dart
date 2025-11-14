class FacturaModel {
  String? id;
  String citaId;          
  String duenoId;        
  String veterinariaId;    
  String servicioId;       
  String servicioNombre;  
  double total;           
  DateTime fechaPago;      

  FacturaModel({
    this.id,
    required this.citaId,
    required this.duenoId,
    required this.veterinariaId,
    required this.servicioId,
    required this.servicioNombre,
    required this.total,
    required this.fechaPago,
  });

  Map<String, dynamic> toJson() {
    return {
      'citaId': citaId,
      'duenoId': duenoId,
      'veterinariaId': veterinariaId,
      'servicioId': servicioId,
      'servicioNombre': servicioNombre,
      'total': total,
      'fechaPago': fechaPago.toIso8601String(),
    };
  }

  factory FacturaModel.fromJson(Map<String, dynamic> json, String id) {
    return FacturaModel(
      id: id,
      citaId: json['citaId'],
      duenoId: json['duenoId'],
      veterinariaId: json['veterinariaId'],
      servicioId: json['servicioId'] ?? '',
      servicioNombre: json['servicioNombre'] ?? '',
      total: (json['total'] as num).toDouble(),
      fechaPago: DateTime.parse(json['fechaPago']),
    );
  }
}
