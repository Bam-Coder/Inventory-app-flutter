import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';

class ExportHistoryScreen extends StatefulWidget {
  const ExportHistoryScreen({super.key});

  @override
  State<ExportHistoryScreen> createState() => _ExportHistoryScreenState();
}

class _ExportHistoryScreenState extends State<ExportHistoryScreen> {
  final ApiService _api = ApiService();
  List<Map<String, dynamic>> _exportHistory = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadExportHistory();
  }

  Future<void> _loadExportHistory() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _api.get('/export/history');
      final List<dynamic> history = response['data'] ?? [];
      
      setState(() {
        _exportHistory = history.map((item) => item as Map<String, dynamic>).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Erreur lors du chargement: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique des exports'),
        actions: [
          IconButton(
            onPressed: _loadExportHistory,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, size: 64, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Text(_error!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadExportHistory,
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : _exportHistory.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          const Text('Aucun export effectué'),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadExportHistory,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _exportHistory.length,
                        itemBuilder: (context, index) {
                          final export = _exportHistory[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: Icon(
                                _getExportIcon(export['type']),
                                color: _getExportColor(export['type']),
                              ),
                              title: Text(export['type'] ?? 'Export'),
                              subtitle: Text(
                                '${export['createdAt'] ?? 'Date inconnue'} • ${export['userName'] ?? 'Utilisateur'}',
                              ),
                              trailing: Icon(
                                Icons.download,
                                color: Colors.green,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }

  IconData _getExportIcon(String? type) {
    switch (type?.toLowerCase()) {
      case 'products':
        return Icons.inventory;
      case 'stock_history':
        return Icons.history;
      case 'low_stock':
        return Icons.warning;
      case 'stats':
        return Icons.analytics;
      default:
        return Icons.file_download;
    }
  }

  Color _getExportColor(String? type) {
    switch (type?.toLowerCase()) {
      case 'products':
        return Colors.blue;
      case 'stock_history':
        return Colors.green;
      case 'low_stock':
        return Colors.orange;
      case 'stats':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
} 