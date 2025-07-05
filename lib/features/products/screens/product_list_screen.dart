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
    Provider.of<ProductProvider>(context, listen: false).loadProducts();
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
                    child: provider.isSearching
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
                                    itemCount: _searchController.text.isNotEmpty
                                        ? provider.searchResults.length
                                        : provider.products.length,
                                    itemBuilder: (context, index) {
                                      final ProductModel product = _searchController.text.isNotEmpty
                                          ? provider.searchResults[index]
                                          : provider.products[index];
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
                  '${product.quantity} unités',
                  style: TextStyle(
                    color: product.quantity <= 10 ? Colors.red : Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${product.price.toStringAsFixed(0)} FCFA',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
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
                  Icon(Icons.history, size: 20, color: Colors.orange),
                  SizedBox(width: 8),
                  Text('Historique'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'adjust',
              child: Row(
                children: [
                  Icon(Icons.tune, size: 20, color: Colors.blue),
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
        Navigator.pushNamed(
          context,
          AppRoutes.productForm,
          arguments: product,
        );
        break;
      case 'delete':
        _showDeleteDialog(context, product, provider);
        break;
      case 'logs':
        _showLogsSheet(context, product);
        break;
      case 'adjust':
        _showAdjustDialog(context, product);
        break;
    }
  }

  void _showDeleteDialog(BuildContext context, ProductModel product, ProductProvider provider) {
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

  void _showLogsSheet(BuildContext context, ProductModel product) {
    final stockProvider = Provider.of<StockProvider>(context, listen: false);
    stockProvider.fetchLogsForProduct(product.id);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _ProductLogsSheet(product: product),
    );
  }

  void _showAdjustDialog(BuildContext context, ProductModel product) {
    showDialog(
      context: context,
      builder: (context) => AdjustStockDialog(product: product),
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
