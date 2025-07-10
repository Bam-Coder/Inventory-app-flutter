import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/export_service.dart';
import '../../../shared/widgets/loading_overlay.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';

class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  final ExportService _exportService = ExportService();
  bool _isExporting = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Export des données'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: LoadingOverlay(
        isLoading: _isExporting,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              Expanded(
                child: _buildExportOptions(),
              ),
              if (_error != null) _buildErrorWidget(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(
              Icons.download,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 8),
            Text(
              'Export des données',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Téléchargez vos données d\'inventaire au format CSV',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            /*ElevatedButton.icon(
              onPressed: _testExportEndpoints,
              icon: const Icon(Icons.wifi_tethering),
              //label: const Text('Tester la connexion'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),*/
          ],
        ),
      ),
    );
  }

  Widget _buildExportOptions() {
    return ListView(
      children: [
        _buildExportCard(
          title: 'Produits',
          subtitle: 'Liste complète de tous vos produits',
          icon: Icons.inventory,
          onTap: () => _exportProducts(),
        ),
        const SizedBox(height: 12),
        _buildExportCard(
          title: 'Historique des stocks',
          subtitle: 'Tous les mouvements de stock',
          icon: Icons.history,
          onTap: () => _exportStockHistory(),
        ),
        const SizedBox(height: 12),
        _buildExportCard(
          title: 'Produits en stock faible',
          subtitle: 'Produits nécessitant un réapprovisionnement',
          icon: Icons.warning,
          onTap: () => _exportLowStock(),
        ),
        const SizedBox(height: 12),
        _buildExportCard(
          title: 'Statistiques d\'inventaire',
          subtitle: 'Rapport détaillé des statistiques',
          icon: Icons.analytics,
          onTap: () => _exportStats(),
        ),
        const SizedBox(height: 12),
        _buildExportCard(
          title: 'Logs d\'audit (Admin)',
          subtitle: 'Historique des actions administratives',
          icon: Icons.admin_panel_settings,
          onTap: () => _exportAuditLogs(),
          isAdminOnly: true,
        ),
      ],
    );
  }

  Widget _buildExportCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    bool isAdminOnly = false,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (isAdminOnly)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'ADMIN',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.download,
                color: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.error, color: Colors.red[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _error!,
              style: TextStyle(color: Colors.red[700]),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => setState(() => _error = null),
            color: Colors.red[600],
          ),
        ],
      ),
    );
  }

  Future<void> _exportProducts() async {
    await _performExport(() => _exportService.exportProducts(), 'produits');
  }

  Future<void> _exportStockHistory() async {
    await _performExport(() => _exportService.exportStockHistory(), 'historique des stocks');
  }

  Future<void> _exportLowStock() async {
    await _performExport(() => _exportService.exportLowStock(), 'produits en stock faible');
  }

  Future<void> _exportStats() async {
    await _performExport(() => _exportService.exportStats(), 'statistiques');
  }

  Future<void> _exportAuditLogs() async {
    await _performExport(() => _exportService.exportAuditLogs(), 'logs d\'audit');
  }

  Future<void> _performExport(Future<String> Function() exportFunction, String type) async {
    setState(() {
      _isExporting = true;
      _error = null;
    });

    try {
      print('🔄 Début de l\'export: $type');
      final filePath = await exportFunction();
      print('📁 Chemin du fichier: $filePath');
      
      await _handleFileResult(filePath, type);
      
    } catch (e) {
      print('❌ Erreur lors de l\'export $type: $e');
      setState(() {
        _error = 'Erreur lors de l\'export des $type: ${e.toString()}';
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      setState(() {
        _isExporting = false;
      });
    }
  }

  Future<void> _handleFileResult(String filePath, String type) async {
    try {
      await _launchUrl(filePath);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export des $type lancé avec succès'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('❌ Erreur lors du traitement du fichier: $e');
      rethrow;
    }
  }

  Future<void> _launchUrl(String filePath) async {
    print('Lien de téléchargement reçu : $filePath');
    if (filePath.startsWith('http')) {
      final uri = Uri.parse(filePath);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showErrorDialog('Impossible d\'ouvrir le lien de téléchargement.\n\n$filePath');
      }
    } else if (filePath.startsWith('data:text/csv')) {
      // Extraire le CSV du data URI
      final csvContent = Uri.decodeComponent(filePath.split(',').last);
      // Proposer de partager ou copier le CSV
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Export CSV'),
            content: const Text('Le CSV a été généré. Vous pouvez le partager ou le copier.'),
            actions: [
              TextButton(
                onPressed: () {
                  Share.share(csvContent, subject: 'Export CSV');
                  Navigator.pop(context);
                },
                child: const Text('Partager'),
              ),
              TextButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: csvContent));
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('CSV copié dans le presse-papier')),
                  );
                },
                child: const Text('Copier'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fermer'),
              ),
            ],
          ),
        );
      }
    } else {
      // Fichier local
      final file = File(filePath);
      if (await file.exists()) {
        final uri = Uri.file(filePath);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        } else {
          _showErrorDialog('Impossible d\'ouvrir le fichier local.\n\n$filePath');
        }
      } else {
        _showErrorDialog('Fichier non trouvé : $filePath');
      }
    }
  }

  void _showErrorDialog(String message) {
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Erreur'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _testExportEndpoints() async {
    try {
      final isWorking = await _exportService.testExportEndpoints();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isWorking 
                  ? 'Connexion aux exports OK' 
                  : 'Erreur de connexion aux exports'
            ),
            backgroundColor: isWorking ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de test: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
} 