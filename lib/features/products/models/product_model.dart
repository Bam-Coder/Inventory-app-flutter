class ProductModel {
  final String id;
  final String name;
  final String? description;
  final int quantity;
  final int reorderThreshold;
  final String unit;
  final String category;
  final String? supplier;
  final String addedBy;
  final bool isDeleted;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? imagePath;

  ProductModel({
    required this.id,
    required this.name,
    this.description,
    required this.quantity,
    required this.reorderThreshold,
    required this.unit,
    required this.category,
    this.supplier,
    required this.addedBy,
    this.isDeleted = false,
    this.createdAt,
    this.updatedAt,
    this.imagePath,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['_id'] ?? json['id'],
      name: json['name'] ?? '',
      description: json['description'],
      quantity: json['quantity'] ?? 0,
      reorderThreshold: json['reorderThreshold'] ?? 5,
      unit: json['unit'] ?? 'pièce',
      category: json['category'] ?? '',
      supplier: json['supplier'],
      addedBy: json['addedBy'] ?? '',
      isDeleted: json['isDeleted'] ?? false,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : null,
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : null,
      imagePath: json['imagePath'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'quantity': quantity,
      'reorderThreshold': reorderThreshold,
      'unit': unit,
      'category': category,
      'supplier': supplier,
      'addedBy': addedBy,
      'isDeleted': isDeleted,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'imagePath': imagePath,
    };
  }

  // Propriété calculée pour la compatibilité
  double get price => 0.0; // Le prix n'existe pas dans le backend

  ProductModel copyWith({
    String? id,
    String? name,
    String? description,
    int? quantity,
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
