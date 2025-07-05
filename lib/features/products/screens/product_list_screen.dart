import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';

import '../../stock/controllers/stock_provider.dart';
import '../controllers/product_provider.dart';
import '../../../shared/navigation/app_routes.dart';
import '../models/product_model.dart';
import 'product_detail_screen.dart';
import '../../export/services/export_service.dart';


class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _lastQuery = '';
  bool _showLowStock = false;

  @override
  void initState() {
    super.initState();
    print('🚀 Initialisation de ProductListScreen');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('🔄 Chargement des produits depuis initState');
      Provider.of<ProductProvider>(context, listen: false).loadProducts();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(ProductProvider provider) {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      provider.clearSearch();
      _lastQuery = '';
    } else if (query != _lastQuery) {
      provider.searchProducts(query);
      _lastQuery = query;
    }
  }

  void _toggleLowStock(ProductProvider provider) async {
    setState(() {
      _showLowStock = !_showLowStock;
    });
    if (_showLowStock) {
      await provider.fetchLowStockProducts();
    }
  }

  void _handleExportAction(String action, ProductProvider provider) async {
    final exportService = ExportService();
    
    try {
      String downloadUrl;
      
      switch (action) {
        case 'export_products':
          downloadUrl = await exportService.exportProducts();
          break;
        case 'export_stock':
          downloadUrl = await exportService.exportStockHistory();
          break;
        default:
          return;
      }
      
      if (context.mounted) {
        // Ouvrir l'URL de téléchargement
        final uri = Uri.parse(downloadUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Export en cours...'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Impossible d\'ouvrir le lien de téléchargement'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur d\'export: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProductProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Produits'),
        actions: [
          // Bouton d'export
          PopupMenuButton<String>(
            onSelected: (value) => _handleExportAction(value, provider),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export_products',
                child: Row(
                  children: [
                    Icon(Icons.file_download, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Exporter les produits'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'export_stock',
                child: Row(
                  children: [
                    Icon(Icons.history, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Exporter l\'historique'),
                  ],
                ),
              ),
            ],
            icon: const Icon(Icons.more_vert),
            tooltip: 'Export',
          ),
          IconButton(
            onPressed: () => provider.loadProducts(),
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualiser',
          ),
          IconButton(
            onPressed: () => _toggleLowStock(provider),
            icon: Icon(_showLowStock ? Icons.list : Icons.warning, color: _showLowStock ? Colors.blue : Colors.orange),
            tooltip: _showLowStock ? 'Tous les produits' : 'Stock faible',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher un produit...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          provider.clearSearch();
                          FocusScope.of(context).unfocus();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (_) => _onSearchChanged(provider),
            ),
          ),
          Expanded(
            child: _showLowStock
                ? (provider.isLoadingLowStock
                    ? const Center(child: CircularProgressIndicator())
                    : provider.lowStockProducts.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.warning, size: 64, color: Colors.orange[400]),
                                const SizedBox(height: 16),
                                Text(
                                  'Aucun produit en stock faible',
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                        color: Colors.grey[600],
                                      ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: provider.lowStockProducts.length,
                            itemBuilder: (context, index) {
                              final ProductModel product = provider.lowStockProducts[index];
                              return _buildProductCard(context, product, provider);
                            },
                          ))
                : RefreshIndicator(
                    onRefresh: () => provider.loadProducts(),
                    child: provider.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : provider.error != null
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Erreur: ${provider.error}',
                                      style: Theme.of(context).textTheme.bodyLarge,
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed: () => provider.loadProducts(),
                                      child: const Text('Réessayer'),
                                    ),
                                  ],
                                ),
                              )
                            : provider.products.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[400]),
                                        const SizedBox(height: 16),
                                        Text(
                                          'Aucun produit',
                                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                                color: Colors.grey[600],
                                              ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Ajoutez votre premier produit',
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                color: Colors.grey[500],
                                              ),
                                        ),
                                      ],
                                    ),
                                  )
                                : _searchController.text.isNotEmpty
                                    ? (provider.isSearching
                                        ? const Center(child: CircularProgressIndicator())
                                        : provider.searchResults.isEmpty
                                            ? Center(
                                                child: Column(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                                                    const SizedBox(height: 16),
                                                    Text(
                                                      'Aucun résultat',
                                                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                                            color: Colors.grey[600],
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                              )
                                            : ListView.builder(
                                                padding: const EdgeInsets.all(16),
                                                itemCount: provider.searchResults.length,
                                                itemBuilder: (context, index) {
                                                  final ProductModel product = provider.searchResults[index];
                                                  return _buildProductCard(context, product, provider);
                                                },
                                              ))
                                    : ListView.builder(
                                        padding: const EdgeInsets.all(16),
                                        itemCount: provider.products.length,
                                        itemBuilder: (context, index) {
                                          final ProductModel product = provider.products[index];
                                          return _buildProductCard(context, product, provider);
                                        },
                                      ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, AppRoutes.productForm);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, ProductModel product, ProductProvider provider) {
    // Debug temporaire
    print('Prix du produit ${product.name}: ${product.price}');
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: product.imagePath != null && product.imagePath!.isNotEmpty
            ? CircleAvatar(
                backgroundImage: FileImage(File(product.imagePath!)),
                radius: 24,
              )
            : CircleAvatar(
                backgroundColor: _getCategoryColor(product.category).withValues(alpha: 0.1),
                child: Icon(
                  Icons.inventory,
                  color: _getCategoryColor(product.category),
                ),
              ),
        title: Text(
          product.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(product.category).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    product.category,
                    style: TextStyle(
                      color: _getCategoryColor(product.category),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${product.quantity} ${product.unit}',
                  style: TextStyle(
                    color: product.quantity <= product.reorderThreshold ? Colors.red : Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.attach_money,
                  size: 16,
                  color: product.price > 0 ? Colors.blue : Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  product.price > 0 
                      ? 'Prix unitaire: ${product.price.toStringAsFixed(0)} FCFA'
                      : 'Prix unitaire: Non défini',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: product.price > 0 ? Colors.blue : Colors.grey[600],
                  ),
                ),
              ],
            ),
            if (product.supplier != null && product.supplier!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Fournisseur: ${product.supplier}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleProductAction(context, product, value, provider),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 8),
                  Text('Modifier'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'update_price',
              child: Row(
                children: [
                  Icon(Icons.attach_money, size: 20, color: Colors.orange),
                  SizedBox(width: 8),
                  Text('Ajuster le prix', style: TextStyle(color: Colors.orange)),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Supprimer', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'logs',
              child: Row(
                children: [
                  Icon(Icons.history, size: 20, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('Historique'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'adjust',
              child: Row(
                children: [
                  Icon(Icons.tune, size: 20, color: Colors.green),
                  SizedBox(width: 8),
                  Text('Ajuster stock'),
                ],
              ),
            ),
          ],
        ),
        isThreeLine: true,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailScreen(product: product),
            ),
          );
        },
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'électronique':
        return Colors.blue;
      case 'vêtements':
        return Colors.purple;
      case 'alimentation':
        return Colors.orange;
      case 'livres':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  void _handleProductAction(BuildContext context, ProductModel product, String action, ProductProvider provider) {
    switch (action) {
      case 'edit':
        Navigator.pushNamed(context, AppRoutes.productForm, arguments: product);
        break;
      case 'update_price':
        _showUpdatePriceDialog(context, product, provider);
        break;
      case 'delete':
        _showDeleteConfirmation(context, product, provider);
        break;
      case 'logs':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fonctionnalité en cours de développement')),
        );
        break;
      case 'adjust':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fonctionnalité en cours de développement')),
        );
        break;
    }
  }

  void _showDeleteConfirmation(BuildContext context, ProductModel product, ProductProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le produit'),
        content: Text('Êtes-vous sûr de vouloir supprimer "${product.name}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await provider.deleteProduct(product.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Produit supprimé avec succès'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _showUpdatePriceDialog(BuildContext context, ProductModel product, ProductProvider provider) {
    final priceController = TextEditingController(text: product.price > 0 ? product.price.toString() : '');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ajuster le prix de ${product.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Afficher le prix actuel
            if (product.price > 0) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Prix actuel: ${product.price.toStringAsFixed(0)} FCFA',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            TextFormField(
              controller: priceController,
              decoration: const InputDecoration(
                labelText: 'Nouveau prix unitaire (FCFA)',
                hintText: 'Entrez le nouveau prix',
                prefixIcon: Icon(Icons.attach_money),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer un prix';
                }
                if (double.tryParse(value) == null) {
                  return 'Prix invalide';
                }
                if (double.parse(value) < 0) {
                  return 'Le prix doit être positif';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            Text(
              'Unité: ${product.unit}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              final newPrice = double.tryParse(priceController.text);
              if (newPrice != null && newPrice >= 0) {
                try {
                  // Utiliser la nouvelle méthode spécifique pour le prix
                  await provider.updateProductPrice(product.id, newPrice);
                  
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Prix de ${product.name} mis à jour: ${newPrice.toStringAsFixed(0)} FCFA'),
                        backgroundColor: Colors.green,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erreur lors de la mise à jour: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Veuillez entrer un prix valide'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            icon: const Icon(Icons.save),
            label: const Text('Enregistrer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class EditProductDialog extends StatefulWidget {
  final ProductModel product;

  const EditProductDialog({super.key, required this.product});

  @override
  State<EditProductDialog> createState() => _EditProductDialogState();
}

class _EditProductDialogState extends State<EditProductDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  late String _category;
  late int _quantity;
  late double _price;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _name = widget.product.name;
    _category = widget.product.category;
    _quantity = widget.product.quantity;
    _price = widget.product.price;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Modifier le produit'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Nom du produit'),
                initialValue: _name,
                validator: (val) =>
                    val == null || val.isEmpty ? 'Champ requis' : null,
                onChanged: (val) => _name = val.trim(),
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Catégorie'),
                initialValue: _category,
                validator: (val) =>
                    val == null || val.isEmpty ? 'Champ requis' : null,
                onChanged: (val) => _category = val.trim(),
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Quantité'),
                initialValue: _quantity.toString(),
                keyboardType: TextInputType.number,
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Champ requis';
                  if (int.tryParse(val) == null) return 'Nombre invalide';
                  return null;
                },
                onChanged: (val) => _quantity = int.tryParse(val) ?? 0,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Prix'),
                initialValue: _price.toString(),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Champ requis';
                  if (double.tryParse(val) == null) return 'Nombre invalide';
                  return null;
                },
                onChanged: (val) => _price = double.tryParse(val) ?? 0,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submitForm,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Modifier'),
        ),
      ],
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final provider = Provider.of<ProductProvider>(context, listen: false);
      await provider.updateProduct(widget.product.id, _name, _category, _quantity, _price);

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Produit modifié avec succès'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

class _ProductLogsSheet extends StatelessWidget {
  final ProductModel product;
  const _ProductLogsSheet({required this.product});

  @override
  Widget build(BuildContext context) {
    final stockProvider = Provider.of<StockProvider>(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.history, color: Colors.orange),
                const SizedBox(width: 8),
                Text('Historique de "${product.name}"', style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 16),
            stockProvider.isLoadingProductLogs
                ? const Center(child: CircularProgressIndicator())
                : stockProvider.productLogs.isEmpty
                    ? Center(
                        child: Text('Aucun mouvement de stock pour ce produit', style: TextStyle(color: Colors.grey[600])),
                      )
                    : SizedBox(
                        height: 300,
                        child: ListView.builder(
                          itemCount: stockProvider.productLogs.length,
                          itemBuilder: (context, index) {
                            final log = stockProvider.productLogs[index];
                            return Card(
                              child: ListTile(
                                leading: Icon(
                                  log.type == 'IN' ? Icons.add : Icons.remove,
                                  color: log.typeColor,
                                ),
                                title: Text('${log.typeLabel} • ${log.quantityLabel}'),
                                subtitle: Text('${log.notes}\n${log.createdAt.day}/${log.createdAt.month}/${log.createdAt.year}'),
                              ),
                            );
                          },
                        ),
                      ),
          ],
        ),
      ),
    );
  }
}

class AdjustStockDialog extends StatefulWidget {
  final ProductModel product;
  const AdjustStockDialog({super.key, required this.product});

  @override
  State<AdjustStockDialog> createState() => _AdjustStockDialogState();
}

class _AdjustStockDialogState extends State<AdjustStockDialog> {
  final _formKey = GlobalKey<FormState>();
  late int _newQuantity;
  String _notes = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _newQuantity = widget.product.quantity;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ajuster le stock'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              decoration: const InputDecoration(labelText: 'Nouvelle quantité'),
              initialValue: _newQuantity.toString(),
              keyboardType: TextInputType.number,
              validator: (val) {
                if (val == null || val.isEmpty) return 'Champ requis';
                if (int.tryParse(val) == null) return 'Nombre invalide';
                return null;
              },
              onChanged: (val) => _newQuantity = int.tryParse(val) ?? 0,
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Notes (optionnel)'),
              maxLines: 2,
              onChanged: (val) => _notes = val,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submitForm,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Ajuster'),
        ),
      ],
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
    });
    try {
      final stockProvider = Provider.of<StockProvider>(context, listen: false);
      await stockProvider.adjustStock(widget.product.id, _newQuantity, _notes.isEmpty ? null : _notes);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Stock ajusté avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
