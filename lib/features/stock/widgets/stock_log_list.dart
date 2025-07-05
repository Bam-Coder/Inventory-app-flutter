import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/stock_log_provider.dart';

class StockLogList extends StatelessWidget {
  final String? productId;
  const StockLogList({super.key, required this.productId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => StockLogProvider()..fetchLogs(productId ?? ''),
      child: Consumer<StockLogProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) return Center(child: CircularProgressIndicator());
          if (provider.errorMessage != null) return Center(child: Text('Erreur: ${provider.errorMessage}'));
          if (provider.logs.isEmpty) return Center(child: Text('Aucun mouvement de stock.'));
          return ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: provider.logs.length,
            itemBuilder: (context, index) {
              final log = provider.logs[index];
              return Card(
                color: Theme.of(context).cardColor,
                child: ListTile(
                  leading: Icon(
                    log.type == 'in'
                        ? Icons.add
                        : log.type == 'out'
                            ? Icons.remove
                            : Icons.tune,
                    color: log.type == 'in'
                        ? Colors.green
                        : log.type == 'out'
                            ? Colors.red
                            : Colors.amber,
                  ),
                  title: Text(
                    '${log.type == 'in' ? 'Entrée' : log.type == 'out' ? 'Sortie' : 'Ajustement'} : ${log.change}',
                  ),
                  subtitle: Text(log.note ?? ''),
                  trailing: Text(
                    '${log.timestamp.day}/${log.timestamp.month}/${log.timestamp.year}',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
} 