import 'package:flutter/material.dart';
import '../../../shared/widgets/notification_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final NotificationService _notificationService = NotificationService();
  
  bool _notificationsEnabled = true;
  int _lowStockThreshold = 5;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final notificationsEnabled = await _notificationService.areNotificationsEnabled();
      final lowStockThreshold = await _notificationService.getLowStockThreshold();
      
      setState(() {
        _notificationsEnabled = notificationsEnabled;
        _lowStockThreshold = lowStockThreshold;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildNotificationSettings(),
                  const SizedBox(height: 24),
                  _buildStockSettings(),
                  const SizedBox(height: 24),
                  _buildAppInfo(),
                ],
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
              Icons.settings,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 8),
            Text(
              'Paramètres',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Configurez vos préférences d\'application',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.notifications,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Notifications',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Activer les notifications'),
              subtitle: const Text('Recevoir des alertes pour les stocks faibles'),
              value: _notificationsEnabled,
              onChanged: (value) async {
                setState(() {
                  _notificationsEnabled = value;
                });
                await _notificationService.setNotificationsEnabled(value);
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        value ? 'Notifications activées' : 'Notifications désactivées',
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
            ),
            const Divider(),
            ListTile(
              title: const Text('Seuil d\'alerte stock faible'),
              subtitle: Text('Alerter quand le stock est inférieur à $_lowStockThreshold'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: _lowStockThreshold > 1
                        ? () => _updateLowStockThreshold(_lowStockThreshold - 1)
                        : null,
                  ),
                  Text(
                    '$_lowStockThreshold',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: _lowStockThreshold < 50
                        ? () => _updateLowStockThreshold(_lowStockThreshold + 1)
                        : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStockSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.inventory,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Gestion des stocks',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.auto_delete),
              title: const Text('Nettoyer le cache'),
              subtitle: const Text('Supprimer les données en cache'),
              onTap: () => _showClearCacheDialog(),
            ),
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('Synchroniser les données'),
              subtitle: const Text('Mettre à jour depuis le serveur'),
              onTap: () => _syncData(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Informations',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.apps),
              title: const Text('Version de l\'application'),
              subtitle: const Text('1.0.0'),
            ),
            ListTile(
              leading: const Icon(Icons.bug_report),
              title: const Text('Signaler un problème'),
              onTap: () => _reportIssue(),
            ),
            ListTile(
              leading: const Icon(Icons.help),
              title: const Text('Aide et support'),
              onTap: () => _showHelp(),
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip),
              title: const Text('Politique de confidentialité'),
              onTap: () => _showPrivacyPolicy(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateLowStockThreshold(int newThreshold) async {
    setState(() {
      _lowStockThreshold = newThreshold;
    });
    
    await _notificationService.setLowStockThreshold(newThreshold);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Seuil d\'alerte mis à jour: $newThreshold'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _showClearCacheDialog() async {
    final confirmed = await _notificationService.showConfirmationDialog(
      context,
      'Nettoyer le cache',
      'Êtes-vous sûr de vouloir supprimer toutes les données en cache ? Cela forcera un rechargement complet des données.',
      confirmText: 'Nettoyer',
      cancelText: 'Annuler',
    );

    if (confirmed) {
      // Ici, vous pouvez ajouter la logique pour nettoyer le cache
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cache nettoyé avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _syncData() async {
    // Ici, vous pouvez ajouter la logique pour synchroniser les données
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Synchronisation en cours...'),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }

  void _reportIssue() {
    _notificationService.showInfoDialog(
      context,
      'Signaler un problème',
      'Pour signaler un problème, veuillez contacter notre équipe de support à support@inventory-app.com',
    );
  }

  void _showHelp() {
    _notificationService.showInfoDialog(
      context,
      'Aide et support',
      'Consultez notre documentation en ligne ou contactez notre équipe de support pour obtenir de l\'aide.',
    );
  }

  void _showPrivacyPolicy() {
    _notificationService.showInfoDialog(
      context,
      'Politique de confidentialité',
      'Vos données sont stockées localement et sur nos serveurs sécurisés. Nous ne partageons jamais vos informations avec des tiers.',
    );
  }
} 