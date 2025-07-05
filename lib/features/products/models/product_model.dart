class ProductModel {
  final String id;
  final String name;
  final String description;
  final int quantity;
  final double price;
  final int reorderThreshold;
  final String unit;
  final String category;
  final String supplier;
  final String addedBy;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? imagePath;

  ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.quantity,
    required this.price,
    required this.reorderThreshold,
    required this.unit,
    required this.category,
    required this.supplier,
    required this.addedBy,
    required this.isDeleted,
    required this.createdAt,
    required this.updatedAt,
    this.imagePath,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    try {
      print('📦 Création ProductModel depuis JSON: $json');
      
      // Gestion sécurisée du prix
      double price = 0.0;
      if (json['price'] != null) {
        if (json['price'] is double) {
          price = json['price'];
        } else if (json['price'] is int) {
          price = json['price'].toDouble();
        } else {
          price = double.tryParse(json['price'].toString()) ?? 0.0;
        }
      }
      
      return ProductModel(
        id: json['_id'] ?? json['id'] ?? '',
        name: json['name'] ?? 'Produit sans nom',
        description: json['description'] ?? '',
        quantity: json['quantity'] is int
            ? json['quantity']
            : int.tryParse(json['quantity'].toString()) ?? 0,
        price: price, // Utiliser la valeur calculée
        reorderThreshold: json['reorderThreshold'] is int
            ? json['reorderThreshold']
            : int.tryParse(json['reorderThreshold'].toString()) ?? 5,
        unit: json['unit'] ?? 'pièce',
        category: json['category'] ?? 'Non catégorisé',
        supplier: json['supplier'] ?? '',
        addedBy: json['addedBy'] ?? '',
        isDeleted: json['isDeleted'] ?? false,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'])
            : DateTime.now(),
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'])
            : DateTime.now(),
        imagePath: json['imagePath'],
      );
    } catch (e) {
      print('❌ Erreur création ProductModel: $e');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'quantity': quantity,
      'price': price,
      'reorderThreshold': reorderThreshold,
      'unit': unit,
      'category': category,
      'supplier': supplier,
      'addedBy': addedBy,
      'isDeleted': isDeleted,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'imagePath': imagePath,
    };
  }

  ProductModel copyWith({
    String? id,
    String? name,
    String? description,
    int? quantity,
    double? price,
    int? reorderThreshold,
    String? unit,
    String? category,
    String? supplier,
    String? addedBy,
    bool? isDeleted,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? imagePath,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      reorderThreshold: reorderThreshold ?? this.reorderThreshold,
      unit: unit ?? this.unit,
      category: category ?? this.category,
      supplier: supplier ?? this.supplier,
      addedBy: addedBy ?? this.addedBy,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      imagePath: imagePath ?? this.imagePath,
    );
  }

  @override
  String toString() {
    return 'ProductModel(id: $id, name: $name, quantity: $quantity, category: $category)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProductModel &&
        other.id == id &&
        other.name == name &&
        other.quantity == quantity &&
        other.category == category;
  }

  @override
  int get hashCode {
    return id.hashCode ^ name.hashCode ^ quantity.hashCode ^ category.hashCode;
  }
}
