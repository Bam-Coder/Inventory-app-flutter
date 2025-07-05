import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/admin_provider.dart';
import '../../dashboard/widgets/stats_card.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    await adminProvider.fetchGlobalStats();
    await adminProvider.fetchUsers();
    await adminProvider.fetchAuditLogs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administration'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Statistiques'),
            Tab(icon: Icon(Icons.people), text: 'Utilisateurs'),
            Tab(icon: Icon(Icons.history), text: 'Audit'),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildStatsTab(),
          _buildUsersTab(),
          _buildAuditTab(),
        ],
      ),
    );
  }

  Widget _buildStatsTab() {
    return Consumer<AdminProvider>(
      builder: (context, adminProvider, child) {
        if (adminProvider.isLoadingStats) {
          return const Center(child: CircularProgressIndicator());
        }

        final stats = adminProvider.globalStats;
        if (stats.isEmpty) {
          return const Center(child: Text('Aucune statistique disponible'));
        }

        return RefreshIndicator(
          onRefresh: () => adminProvider.fetchGlobalStats(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Statistiques Globales',
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
                    StatsCard(
                      icon: Icons.people,
                      title: 'Total Utilisateurs',
                      subtitle: '${stats['totalUsers'] ?? 0}',
                      color: Colors.blue,
                    ),
                    StatsCard(
                      icon: Icons.inventory,
                      title: 'Total Produits',
                      subtitle: '${stats['totalProducts'] ?? 0}',
                      color: Colors.green,
                    ),
                    StatsCard(
                      icon: Icons.category,
                      title: 'Catégories',
                      subtitle: '${stats['totalCategories'] ?? 0}',
                      color: Colors.purple,
                    ),
                    StatsCard(
                      icon: Icons.trending_up,
                      title: 'Valeur Totale',
                      subtitle: '${stats['totalValue'] ?? 0} FCFA',
                      color: Colors.orange,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (stats['categoryStats'] != null && stats['categoryStats'] is List)
                  _buildCategoryStats(stats['categoryStats'] as List<dynamic>),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoryStats(List<dynamic> categoryStats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Répartition par Catégorie',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...categoryStats.map((stat) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(stat['_id']?.toString() ?? 'Inconnu'),
                  Text(
                    '${stat['count'] ?? 0} produits',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildUsersTab() {
    return Consumer<AdminProvider>(
      builder: (context, adminProvider, child) {
        if (adminProvider.isLoadingUsers) {
          return const Center(child: CircularProgressIndicator());
        }

        if (adminProvider.users.isEmpty) {
          return const Center(child: Text('Aucun utilisateur trouvé'));
        }

        return RefreshIndicator(
          onRefresh: () => adminProvider.fetchUsers(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: adminProvider.users.length,
            itemBuilder: (context, index) {
              final user = adminProvider.users[index];
              return _buildUserCard(user, adminProvider);
            },
          ),
        );
      },
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user, AdminProvider adminProvider) {
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
                onSelected: (value) => _handleUserAction(value, user, adminProvider),
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
  }

  Widget _buildAuditTab() {
    return Consumer<AdminProvider>(
      builder: (context, adminProvider, child) {
        if (adminProvider.isLoadingAudit) {
          return const Center(child: CircularProgressIndicator());
        }

        if (adminProvider.auditLogs.isEmpty) {
          return const Center(child: Text('Aucun log d\'audit disponible'));
        }

        return RefreshIndicator(
          onRefresh: () => adminProvider.fetchAuditLogs(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: adminProvider.auditLogs.length,
            itemBuilder: (context, index) {
              final log = adminProvider.auditLogs[index];
              return _buildAuditLogCard(log);
            },
          ),
        );
      },
    );
  }

  Widget _buildAuditLogCard(Map<String, dynamic> log) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getActionColor(log['action']).withValues(alpha: 0.1),
          child: Icon(
            _getActionIcon(log['action']),
            color: _getActionColor(log['action']),
          ),
        ),
        title: Text(
          _getActionLabel(log['action']),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Par: ${log['userId']?['name'] ?? 'Utilisateur inconnu'}'),
            Text('Date: ${_formatDate(_parseDate(log['timestamp']))}'),
            if (log['details'] != null)
              Text('Détails: ${log['details'].toString()}'),
          ],
        ),
      ),
    );
  }

  void _handleUserAction(String action, Map<String, dynamic> user, AdminProvider adminProvider) {
    switch (action) {
      case 'delete':
        _showDeleteUserDialog(user, adminProvider);
        break;
    }
  }

  void _showDeleteUserDialog(Map<String, dynamic> user, AdminProvider adminProvider) {
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

  Color _getActionColor(String? action) {
    switch (action) {
      case 'create_product':
        return Colors.green;
      case 'update_product':
        return Colors.blue;
      case 'delete_product':
        return Colors.red;
      case 'create_user':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getActionIcon(String? action) {
    switch (action) {
      case 'create_product':
        return Icons.add_box;
      case 'update_product':
        return Icons.edit;
      case 'delete_product':
        return Icons.delete;
      case 'create_user':
        return Icons.person_add;
      default:
        return Icons.info;
    }
  }

  String _getActionLabel(String? action) {
    switch (action) {
      case 'create_product':
        return 'Création de produit';
      case 'update_product':
        return 'Modification de produit';
      case 'delete_product':
        return 'Suppression de produit';
      case 'create_user':
        return 'Création d\'utilisateur';
      default:
        return action ?? 'Action inconnue';
    }
  }

  DateTime _parseDate(String? timestamp) {
    if (timestamp == null) return DateTime.now();
    try {
      return DateTime.parse(timestamp);
    } catch (e) {
      return DateTime.now();
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} à ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
} 