// stock_log_model.dart
import 'package:flutter/material.dart';
import '../../../core/utils/logger.dart';

class StockLogModel {
  final String id;
  final String productId;
  final String productName;
  final int change; // Changement de quantité (positif ou négatif)
  final String type; // 'in', 'out', 'adjustment'
  final String? note;
  final DateTime timestamp;
  final String userId;
  final String userName;

  StockLogModel({
    required this.id,
    required this.productId,
    required this.productName,
    required this.change,
    required this.type,
    this.note,
    required this.timestamp,
    required this.userId,
    required this.userName,
  });

  factory StockLogModel.fromJson(Map<String, dynamic> json) {
    try {
      return StockLogModel(
        id: json['_id'] ?? json['id'] ?? '',
        productId: json['productId'] ?? '',
        productName: json['productName'] ?? json['product']?['name'] ?? 'Produit inconnu',
        change: json['change'] is int
          ? json['change']
          : int.tryParse(json['change'].toString()) ?? 0,
        type: json['type'] ?? 'in',
        note: json['note'],
        timestamp: json['timestamp'] != null 
            ? DateTime.parse(json['timestamp'])
            : DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
        userId: json['userId'] ?? '',
        userName: json['userName'] ?? json['userId']?['name'] ?? 'Utilisateur',
      );
    } catch (e) {
      AppLogger.error('Erreur lors de la création du StockLogModel', e);
      AppLogger.debug('JSON reçu: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'productName': productName,
      'change': change,
      'type': type,
      'note': note,
      'timestamp': timestamp.toIso8601String(),
      'userId': userId,
      'userName': userName,
    };
  }

  // Propriétés calculées pour la compatibilité
  int get quantity => change.abs();
  String get typeLabel {
    switch (type.toLowerCase()) {
      case 'in':
        return 'Entrée';
      case 'out':
        return 'Sortie';
      case 'adjustment':
        return 'Ajustement';
      default:
        return 'Mouvement';
    }
  }
  
  String get quantityLabel {
    if (change > 0) {
      return '+${change.abs()}';
    } else {
      return '-${change.abs()}';
    }
  }
  
  Color get typeColor {
    switch (type.toLowerCase()) {
      case 'in':
        return Colors.green;
      case 'out':
        return Colors.red;
      case 'adjustment':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  // Propriétés pour la compatibilité avec l'ancien code
  String get notes => note ?? '';
  DateTime get createdAt => timestamp;
  String get createdBy => userName;
}

String extractErrorMessage(dynamic error) {
  final errorStr = error.toString();
  final regex = RegExp(r'"message":"([^"]+)"');
  final match = regex.firstMatch(errorStr);
  if (match != null) {
    return match.group(1)!;
  }
  return errorStr;
}