import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product_model.dart';
import '../controllers/product_provider.dart';
import '../../stock/controllers/stock_provider.dart';
import '../../stock/models/stock_log_model.dart';
import 'dart:io';

class ProductDetailScreen extends StatefulWidget {
  final ProductModel product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _adjustQuantityController = TextEditingController();
  final TextEditingController _adjustNotesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadStockHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _adjustQuantityController.dispose();
    _adjustNotesController.dispose();
    super.dispose();
  }

  Future<void> _loadStockHistory() async {
    final stockProvider = Provider.of<StockProvider>(context, listen: false);
    await stockProvider.fetchLogsForProduct(widget.product.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product.name),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.info), text: 'Détails'),
            Tab(icon: Icon(Icons.history), text: 'Historique'),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => _showAdjustStockDialog(context),
            icon: const Icon(Icons.tune),
            tooltip: 'Ajuster le stock',
          ),
          IconButton(
            onPressed: () => _showEditDialog(context),
            icon: const Icon(Icons.edit),
            tooltip: 'Modifier',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDetailsTab(),
          _buildHistoryTab(),
        ],
      ),
    );
  }

  Widget _buildDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      widget.product.imagePath != null && widget.product.imagePath!.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(30),
                              child: Image.file(
                                File(widget.product.imagePath!),
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                              ),
                            )
                          : CircleAvatar(
                              radius: 30,
                              backgroundColor: _getCategoryColor(widget.product.category).withValues(alpha: 0.1),
                              child: Icon(
                                Icons.inventory,
                                size: 30,
                                color: _getCategoryColor(widget.product.category),
                              ),
                            ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.product.name,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getCategoryColor(widget.product.category).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                widget.product.category,
                                style: TextStyle(
                                  color: _getCategoryColor(widget.product.category),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildInfoRow('Quantité en stock', '${widget.product.quantity} unités', 
                    widget.product.quantity <= 10 ? Colors.red : Colors.green),
                  _buildInfoRow('Prix unitaire', '${widget.product.price.toStringAsFixed(0)} FCFA', Colors.blue),
                  if (widget.product.supplier != null && widget.product.supplier!.isNotEmpty)
                    _buildInfoRow('Fournisseur', widget.product.supplier!, Colors.purple),
                  _buildInfoRow('ID du produit', widget.product.id, Colors.grey),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (widget.product.quantity <= 10)
            Card(
              color: Colors.orange.withValues(alpha: 0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Stock faible ! Pensez à réapprovisionner.',
                        style: TextStyle(
                          color: Colors.orange[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    return Consumer<StockProvider>(
      builder: (context, stockProvider, child) {
        if (stockProvider.isLoadingProductLogs) {
          return const Center(child: CircularProgressIndicator());
        }

        if (stockProvider.productLogs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Aucun mouvement de stock',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _loadStockHistory,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: stockProvider.productLogs.length,
            itemBuilder: (context, index) {
              final log = stockProvider.productLogs[index];
              return _buildStockLogCard(log);
            },
          ),
        );
      },
    );
  }

  Widget _buildStockLogCard(StockLogModel log) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: log.typeColor.withValues(alpha: 0.1),
          child: Icon(
            log.type == 'IN' ? Icons.add : Icons.remove,
            color: log.typeColor,
          ),
        ),
        title: Text(
          '${log.typeLabel} - ${log.quantityLabel}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (log.notes.isNotEmpty)
              Text(log.notes),
            Text(
              'Par ${log.createdBy} • ${_formatDate(log.createdAt)}',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
        trailing: Text(
          log.typeLabel,
          style: TextStyle(
            color: log.typeColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  void _showAdjustStockDialog(BuildContext context) {
    _adjustQuantityController.clear();
    _adjustNotesController.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajuster le stock'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _adjustQuantityController,
              decoration: const InputDecoration(
                labelText: 'Nouvelle quantité',
                hintText: 'Entrez la nouvelle quantité',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _adjustNotesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optionnel)',
                hintText: 'Raison de l\'ajustement',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => _adjustStock(context),
            child: const Text('Ajuster'),
          ),
        ],
      ),
    );
  }

  Future<void> _adjustStock(BuildContext context) async {
    final newQuantity = int.tryParse(_adjustQuantityController.text);
    if (newQuantity == null || newQuantity < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer une quantité valide'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.pop(context);
    
    final stockProvider = Provider.of<StockProvider>(context, listen: false);
    final productProvider = Provider.of<ProductProvider>(context, listen: false);

    try {
      await stockProvider.adjustStock(
        widget.product.id,
        newQuantity,
        _adjustNotesController.text.isNotEmpty ? _adjustNotesController.text : null,
      );

      // Recharger les données
      await productProvider.loadProducts(forceRefresh: true);
      await _loadStockHistory();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Stock ajusté avec succès'),
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
  }

  void _showEditDialog(BuildContext context) {
    // Navigation vers l'écran de modification
    Navigator.pushNamed(
      context,
      '/product/edit',
      arguments: widget.product,
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} à ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
} 