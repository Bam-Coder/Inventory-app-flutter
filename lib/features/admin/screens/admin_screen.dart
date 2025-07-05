import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/admin_provider.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AdminProvider()..fetchUsers(),
      child: Consumer<AdminProvider>(
        builder: (context, provider, _) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Administration'),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              bottom: TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: "Vue d'ensemble"),
                  Tab(text: "Utilisateurs"),
                  Tab(text: "Paramètres"),
                ],
              ),
            ),
            body: TabBarView(
              controller: _tabController,
              children: [
                // Vue d'ensemble
                _OverviewTab(provider: provider),
                // Utilisateurs
                _UsersTab(provider: provider),
                // Paramètres
                _SettingsTab(),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final AdminProvider provider;
  const _OverviewTab({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, adminProvider, child) {
        if (adminProvider.isLoadingStats) {
          return const Center(child: CircularProgressIndicator());
        }

        final stats = adminProvider.globalStats;
        if (stats.isEmpty) {
          return const Center(child: Text('Aucune statistique disponible'));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Vue d\'ensemble',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.2,
                children: [
                  _buildStatCard(
                    icon: Icons.people,
                    title: 'Total Utilisateurs',
                    value: '${stats['totalUsers'] ?? 0}',
                    color: Colors.blue,
                  ),
                  _buildStatCard(
                    icon: Icons.inventory,
                    title: 'Total Produits',
                    value: '${stats['totalProducts'] ?? 0}',
                    color: Colors.green,
                  ),
                  _buildStatCard(
                    icon: Icons.category,
                    title: 'Catégories',
                    value: '${stats['totalCategories'] ?? 0}',
                    color: Colors.purple,
                  ),
                  _buildStatCard(
                    icon: Icons.trending_up,
                    title: 'Valeur Totale',
                    value: '${stats['totalValue'] ?? 0} €',
                    color: Colors.orange,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: color,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UsersTab extends StatelessWidget {
  final AdminProvider provider;
  const _UsersTab({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, adminProvider, child) {
        if (adminProvider.isLoadingUsers) {
          return const Center(child: CircularProgressIndicator());
        }

        if (adminProvider.error != null) {
          return Center(child: Text('Erreur: ${adminProvider.error}'));
        }

        if (adminProvider.users.isEmpty) {
          return const Center(child: Text('Aucun utilisateur trouvé.'));
        }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
          itemCount: adminProvider.users.length,
      itemBuilder: (context, index) {
            final user = adminProvider.users[index];
        return Card(
              margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getRoleColor(user['role']).withValues(alpha: 0.1),
                  child: Icon(
                    Icons.person,
                    color: _getRoleColor(user['role']),
                  ),
                ),
                title: Text(
                  user['name'] ?? 'Nom inconnu',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user['email'] ?? 'Email inconnu'),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getRoleColor(user['role']).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        user['role'] ?? 'Utilisateur',
                        style: TextStyle(
                          color: _getRoleColor(user['role']),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                trailing: user['role'] != 'admin'
                    ? PopupMenuButton<String>(
                        onSelected: (value) => _handleUserAction(value, user, adminProvider, context),
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Supprimer', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                      )
                    : null,
              ),
            );
          },
        );
      },
    );
  }

  Color _getRoleColor(String? role) {
    switch (role) {
      case 'admin':
        return Colors.red;
      case 'manager':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  void _handleUserAction(String action, Map<String, dynamic> user, AdminProvider adminProvider, BuildContext context) {
    switch (action) {
      case 'delete':
        _showDeleteUserDialog(user, adminProvider, context);
        break;
    }
  }

  void _showDeleteUserDialog(Map<String, dynamic> user, AdminProvider adminProvider, BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Êtes-vous sûr de vouloir supprimer l\'utilisateur "${user['name']}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await adminProvider.deleteUser(user['_id']);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Utilisateur supprimé avec succès'),
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
}

class _SettingsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Paramètres d\'administration',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.backup),
                  title: const Text('Sauvegarde des données'),
                  subtitle: const Text('Exporter toutes les données'),
                  onTap: () {
                    // TODO: Implémenter la sauvegarde
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Fonctionnalité à venir')),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.security),
                  title: const Text('Sécurité'),
                  subtitle: const Text('Paramètres de sécurité'),
                  onTap: () {
                    // TODO: Implémenter les paramètres de sécurité
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Fonctionnalité à venir')),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.settings),
                  title: const Text('Configuration système'),
                  subtitle: const Text('Paramètres avancés'),
                  onTap: () {
                    // TODO: Implémenter la configuration système
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Fonctionnalité à venir')),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 