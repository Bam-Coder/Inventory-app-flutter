class AuditLogModel {
  final String id;
  final String userId;
  final String action;
  final Map<String, dynamic> details;
  final DateTime timestamp;

  AuditLogModel({
    required this.id,
    required this.userId,
    required this.action,
    required this.details,
    required this.timestamp,
  });

  factory AuditLogModel.fromJson(Map<String, dynamic> json) {
    return AuditLogModel(
      id: json['_id'] ?? '',
      userId: json['userId'] ?? '',
      action: json['action'] ?? '',
      details: Map<String, dynamic>.from(json['details'] ?? {}),
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'userId': userId,
      'action': action,
      'details': details,
      'timestamp': timestamp.toIso8601String(),
    };
  }
} 