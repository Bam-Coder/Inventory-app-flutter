import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/stock_provider.dart';
import '../models/stock_log_model.dart';


class StockHistoryScreen extends StatefulWidget {
  const StockHistoryScreen({super.key});

  @override
  State<StockHistoryScreen> createState() => _StockHistoryScreenState();
}

class _StockHistoryScreenState extends State<StockHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<StockProvider>(context, listen: false).loadStockHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique des stocks'),
        actions: [
          IconButton(
            onPressed: () {
              Provider.of<StockProvider>(context, listen: false).loadStockHistory();
            },
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: Consumer<StockProvider>(
        builder: (context, stockProvider, child) {
          if (stockProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (stockProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Erreur: ${stockProvider.error}',
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => stockProvider.loadStockHistory(),
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          if (stockProvider.stockLogs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Aucun mouvement de stock',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Les mouvements de stock apparaîtront ici',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => stockProvider.loadStockHistory(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: stockProvider.stockLogs.length,
              itemBuilder: (context, index) {
                try {
                  final StockLogModel log = stockProvider.stockLogs[index];
                  return _buildStockLogCard(log);
                } catch (e) {
                  return Card(
                    color: Colors.red[50],
                    child: ListTile(
                      leading: const Icon(Icons.error, color: Colors.red),
                      title: const Text('Erreur de données'),
                      subtitle: Text('Impossible d\'afficher ce mouvement : $e'),
                    ),
                  );
                }
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showAddStockDialog(context);
        },
        icon: const Icon(Icons.add),
        label: const Text('Mouvement'),
      ),
    );
  }

  Widget _buildStockLogCard(StockLogModel log) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: log.typeColor.withOpacity(0.1),
          child: Icon(
            log.typeColor == Colors.green
                ? Icons.add
                : log.typeColor == Colors.red
                    ? Icons.remove
                    : Icons.tune,
            color: log.typeColor,
          ),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                log.productName != 'Produit inconnu'
                  ? log.productName
                  : log.productId,
                style: const TextStyle(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '${log.createdAt.day.toString().padLeft(2, '0')}/'
              '${log.createdAt.month.toString().padLeft(2, '0')}/'
              '${log.createdAt.year} '
              '${log.createdAt.hour.toString().padLeft(2, '0')}:'
              '${log.createdAt.minute.toString().padLeft(2, '0')}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
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
                    color: log.typeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    log.typeLabel,
                    style: TextStyle(
                      color: log.typeColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  log.quantityLabel,
                  style: TextStyle(
                    color: log.typeColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            if (log.notes.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                log.notes,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  void _showAddStockDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddStockDialog(),
    );
  }
}

class AddStockDialog extends StatefulWidget {
  const AddStockDialog({super.key});

  @override
  State<AddStockDialog> createState() => _AddStockDialogState();
}

class _AddStockDialogState extends State<AddStockDialog> {
  final _formKey = GlobalKey<FormState>();
  String _selectedProductId = '';
  int _quantity = 0;
  String _type = 'IN';
  String _notes = '';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ajouter un mouvement de stock'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Sélection du produit (simplifié pour l'exemple)
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'ID du produit',
                  hintText: 'Entrez l\'ID du produit',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un ID de produit';
                  }
                  return null;
                },
                onChanged: (value) {
                  _selectedProductId = value;
                },
              ),
              const SizedBox(height: 16),
              
              // Type de mouvement
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Type de mouvement'),
                value: _type,
                items: const [
                  DropdownMenuItem(value: 'IN', child: Text('Entrée de stock')),
                  DropdownMenuItem(value: 'OUT', child: Text('Sortie de stock')),
                ],
                onChanged: (value) {
                  setState(() {
                    _type = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              
              // Quantité
              TextFormField(
                decoration: const InputDecoration(labelText: 'Quantité'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer une quantité';
                  }
                  if (int.tryParse(value) == null || int.parse(value) <= 0) {
                    return 'Veuillez entrer un nombre positif';
                  }
                  return null;
                },
                onChanged: (value) {
                  _quantity = int.tryParse(value) ?? 0;
                },
              ),
              const SizedBox(height: 16),
              
              // Notes
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Notes (optionnel)',
                  hintText: 'Raison du mouvement...',
                ),
                maxLines: 2,
                onChanged: (value) {
                  _notes = value;
                },
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
              : const Text('Ajouter'),
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
      
      if (_selectedProductId.isEmpty) {
        throw Exception('Veuillez entrer un ID de produit');
      }
      
      if (_type == 'IN') {
        await stockProvider.addStockIn(_selectedProductId, _quantity, _notes.isEmpty ? null : _notes);
      } else {
        await stockProvider.addStockOut(_selectedProductId, _quantity, _notes.isEmpty ? null : _notes);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Mouvement de stock ajouté avec succès'),
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
