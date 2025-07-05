import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/stock_provider.dart';

enum StockActionType { inStock, outStock, adjust }

class StockTransactionScreen extends StatefulWidget {
  final String productId;
  final String productName;
  final int currentStock;

  const StockTransactionScreen({
    super.key,
    required this.productId,
    required this.productName,
    required this.currentStock,
  });

  @override
  State<StockTransactionScreen> createState() => _StockTransactionScreenState();
}

class _StockTransactionScreenState extends State<StockTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  StockActionType _actionType = StockActionType.inStock;
  int _quantity = 0;
  String _note = '';

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => StockProvider(),
      child: Consumer<StockProvider>(
        builder: (context, provider, _) {
          return Scaffold(
            appBar: AppBar(title: Text('Stock Transaction')),
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    // Produit
                    ListTile(
                      leading: Icon(Icons.inventory, color: Theme.of(context).colorScheme.primary),
                      title: Text(widget.productName, style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Stock actuel : ${widget.currentStock}'),
                    ),
                    SizedBox(height: 16),
                    // Type de transaction
                    Text('Type de transaction', style: Theme.of(context).textTheme.titleMedium),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _actionButton(context, StockActionType.inStock, Icons.add, "Entrée"),
                        _actionButton(context, StockActionType.outStock, Icons.remove, "Sortie"),
                        _actionButton(context, StockActionType.adjust, Icons.tune, "Ajustement"),
                      ],
                    ),
                    SizedBox(height: 16),
                    // Quantité
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Quantité',
                        prefixIcon: Icon(Icons.numbers),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) => v == null || int.tryParse(v) == null ? 'Nombre requis' : null,
                      onSaved: (v) => _quantity = int.tryParse(v ?? '0') ?? 0,
                    ),
                    SizedBox(height: 16),
                    // Note
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Note (optionnel)',
                        prefixIcon: Icon(Icons.note),
                      ),
                      onSaved: (v) => _note = v ?? '',
                    ),
                    SizedBox(height: 24),
                    provider.isLoading
                        ? Center(child: CircularProgressIndicator())
                        : ElevatedButton.icon(
                            icon: Icon(Icons.check),
                            label: Text('Valider'),
                            onPressed: () async {
                              if (_formKey.currentState?.validate() ?? false) {
                                _formKey.currentState?.save();
                                switch (_actionType) {
                                  case StockActionType.inStock:
                                    await provider.addStockIn(widget.productId, _quantity, _note);
                                    break;
                                  case StockActionType.outStock:
                                    await provider.addStockOut(widget.productId, _quantity, _note);
                                    break;
                                  case StockActionType.adjust:
                                    await provider.adjustStock(widget.productId, _quantity, _note);
                                    break;
                                }
                                if (provider.error == null) {
                                  Navigator.pop(context, true);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(provider.error!)),
                                  );
                                }
                              }
                            },
                          ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _actionButton(BuildContext context, StockActionType type, IconData icon, String label) {
    final isSelected = _actionType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _actionType = type),
        child: Card(
          color: isSelected ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2) : Theme.of(context).cardColor,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              children: [
                Icon(icon, color: isSelected ? Theme.of(context).colorScheme.primary : Colors.white54),
                SizedBox(height: 4),
                Text(label, style: TextStyle(color: isSelected ? Theme.of(context).colorScheme.primary : Colors.white70)),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 