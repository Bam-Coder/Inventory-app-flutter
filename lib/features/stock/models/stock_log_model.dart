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
      // Gestion sécurisée du userId
      String userId = '';
      String userName = 'Utilisateur';
      
      if (json['userId'] != null) {
        if (json['userId'] is String) {
          userId = json['userId'];
        } else if (json['userId'] is Map) {
          userId = json['userId']['_id'] ?? json['userId']['id'] ?? '';
          userName = json['userId']['name'] ?? 'Utilisateur';
        }
      }
      
      // Gestion sécurisée du productName
      String productName = 'Produit inconnu';
      String productId = '';
      if (json['productId'] != null && json['productId'] is String) {
        productId = json['productId'];
      } else if (json['product'] != null && json['product'] is Map && json['product']['_id'] != null) {
        productId = json['product']['_id'];
      } else if (json['_id'] != null) {
        productId = json['_id'];
      }
      
      if (json['productName'] != null && json['productName'].toString().isNotEmpty) {
        productName = json['productName'];
      } else if (json['product'] != null && json['product'] is Map) {
        productName = json['product']['name'] ?? 'Produit inconnu';
      } else if (productId.isNotEmpty) {
        // Format plus court et lisible
        productName = 'Produit #${productId.length > 8 ? productId.substring(0, 8) : productId}';
      }
      
      // Gestion sécurisée de la date
      DateTime timestamp;
      try {
        if (json['timestamp'] != null) {
          timestamp = DateTime.parse(json['timestamp']);
        } else if (json['createdAt'] != null) {
          timestamp = DateTime.parse(json['createdAt']);
        } else {
          timestamp = DateTime.now();
        }
      } catch (e) {
        timestamp = DateTime.now();
      }
      
      return StockLogModel(
        id: json['_id'] ?? json['id'] ?? '',
        productId: productId,
        productName: productName,
        change: json['change'] is int
          ? json['change']
          : int.tryParse(json['change'].toString()) ?? 0,
        type: json['type'] ?? 'in',
        note: json['note'],
        timestamp: timestamp,
        userId: userId,
        userName: json['userName'] ?? userName,
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