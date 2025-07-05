import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../features/auth/controllers/auth_provider.dart';
import '../../../features/products/controllers/product_provider.dart';
import '../../../features/stock/controllers/stock_provider.dart';
import '../../dashboard/widgets/stats_card.dart';
import '../../../shared/navigation/app_routes.dart';
import '../../products/screens/product_detail_screen.dart';
import '../../products/screens/product_list_screen.dart';
import '../../stock/screens/stock_history_screen.dart';
import '../../../core/utils/logger.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  
  final List<Widget> _screens = [
    const DashboardContent(),
    const ProductListScreen(),
    const StockHistoryScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Charge les données au démarrage avec force refresh
      Provider.of<ProductProvider>(context, listen: false).refreshAll();
      Provider.of<StockProvider>(context, listen: false).loadStockHistory(forceRefresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitle()),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.profile);
            },
            icon: const Icon(Icons.person),
            tooltip: 'Mon profil',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'logout':
                  auth.logout();
                  Navigator.pushReplacementNamed(context, AppRoutes.login);
                  break;
                case 'admin':
                  Navigator.pushNamed(context, AppRoutes.adminDashboard);
                  break;
                case 'test':
                  _runIntegrationTests(context);
                  break;
              }
            },
            itemBuilder: (context) => [
              if (user?.role == 'admin')
                const PopupMenuItem(
                  value: 'admin',
                  child: Row(
                    children: [
                      Icon(Icons.admin_panel_settings),
                      SizedBox(width: 8),
                      Text('Administration'),
                    ],
                  ),
                ),
              if (user?.role == 'admin')
                const PopupMenuItem(
                  value: 'test',
                  child: Row(
                    children: [
                      Icon(Icons.bug_report),
                      SizedBox(width: 8),
                      Text('Tests d\'intégration'),
                    ],
                  ),
                ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text('Déconnexion'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      drawer: _buildDrawer(context, user),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory),
            label: 'Produits',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Stock',
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  String _getTitle() {
    switch (_currentIndex) {
      case 0:
        return 'Dashboard';
      case 1:
        return 'Produits';
      case 2:
        return 'Historique Stock';
      default:
        return 'Dashboard';
    }
  }

  Widget _buildDrawer(BuildContext context, user) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.person,
                    size: 30,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  user?.name ?? 'Utilisateur',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  user?.email ?? '',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            selected: _currentIndex == 0,
            onTap: () {
              setState(() {
                _currentIndex = 0;
              });
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.inventory),
            title: const Text('Produits'),
            selected: _currentIndex == 1,
            onTap: () {
              setState(() {
                _currentIndex = 1;
              });
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Historique Stock'),
            selected: _currentIndex == 2,
            onTap: () {
              setState(() {
                _currentIndex = 2;
              });
              Navigator.pop(context);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.analytics),
            title: const Text('Rapports'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.reports);
            },
          ),
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('Export'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.export);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Mon Profil'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.profile);
            },
          ),
          if (user?.role == 'admin') ...[
            ListTile(
              leading: const Icon(Icons.admin_panel_settings),
              title: const Text('Administration'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.adminDashboard);
              },
            ),
          ],
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Déconnexion'),
            onTap: () {
              Provider.of<AuthProvider>(context, listen: false).logout();
              Navigator.pushReplacementNamed(context, AppRoutes.login);
            },
          ),
        ],
      ),
    );
  }

  Widget? _buildFloatingActionButton() {
    switch (_currentIndex) {
      case 1: // Produits
        return FloatingActionButton(
          onPressed: () {
            Navigator.pushNamed(context, AppRoutes.productForm);
          },
          child: const Icon(Icons.add),
        );
      case 2: // Stock
        return FloatingActionButton(
          onPressed: () {
            // Naviguer vers l'écran de stock qui a son propre FAB
            setState(() {
              _currentIndex = 2;
            });
          },
          child: const Icon(Icons.add),
        );
      default:
        return null;
    }
  }

  void _runIntegrationTests(BuildContext context) async {
    try {
      // Import dynamique pour éviter les erreurs de compilation
      await _testAuthentication(context);
      await _testProducts(context);
      await _testStock(context);
      await _testProfileUpdate(context);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tests d\'intégration terminés - Vérifiez la console'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors des tests: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _testAuthentication(BuildContext context) async {
          AppLogger.info('🧪 Test d\'authentification...');
    final auth = Provider.of<AuthProvider>(context, listen: false);
    
    // Test de récupération du profil
    try {
      await auth.fetchProfile();
              AppLogger.success('✅ Profil récupéré: SUCCÈS');
    } catch (e) {
              AppLogger.error('❌ Erreur profil', e);
    }
  }

  Future<void> _testProducts(BuildContext context) async {
          AppLogger.info('🧪 Test des produits...');
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    
    try {
      await productProvider.loadProducts();
              AppLogger.success('✅ Produits chargés: SUCCÈS (${productProvider.products.length} produits)');
    } catch (e) {
              AppLogger.error('❌ Erreur produits', e);
    }
  }

  Future<void> _testStock(BuildContext context) async {
          AppLogger.info('🧪 Test du stock...');
    final stockProvider = Provider.of<StockProvider>(context, listen: false);
    
    try {
      await stockProvider.loadStockHistory();
              AppLogger.success('✅ Stock chargé: SUCCÈS (${stockProvider.stockLogs.length} mouvements)');
    } catch (e) {
              AppLogger.error('❌ Erreur stock', e);
    }
  }

  Future<void> _testProfileUpdate(BuildContext context) async {
          AppLogger.info('🧪 Test de mise à jour du profil...');
    final auth = Provider.of<AuthProvider>(context, listen: false);
    
    try {
      await auth.fetchProfile();
              AppLogger.success('✅ Mise à jour profil: SUCCÈS');
    } catch (e) {
              AppLogger.error('❌ Erreur mise à jour', e);
    }
  }

}

class DashboardContent extends StatefulWidget {
  const DashboardContent({super.key});

  @override
  State<DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<DashboardContent> {
  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;

    return RefreshIndicator(
      onRefresh: () async {
        // Forcer le rechargement complet
        await Provider.of<ProductProvider>(context, listen: false).refreshAll();
        await Provider.of<StockProvider>(context, listen: false).loadStockHistory(forceRefresh: true);
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec informations utilisateur
            _buildUserHeader(context, user),
            const SizedBox(height: 24),
            
            // Statistiques
            _buildStatisticsSection(context),
            const SizedBox(height: 24),
            
            // Actions rapides
            _buildQuickActions(context),
            const SizedBox(height: 24),
            
            // Alertes de stock faible
            _buildLowStockAlerts(context),
            const SizedBox(height: 24),
            
            // Derniers mouvements de stock
            _buildRecentStockMovements(context),
          ],
        ),
      ),
    );
  }

  Widget _buildUserHeader(BuildContext context, user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              child: Icon(
                Icons.person,
                size: 30,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bienvenue, ${user?.name ?? 'Utilisateur'} 👋',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Gérez votre inventaire efficacement',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Statistiques',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Consumer<ProductProvider>(
          builder: (context, productProvider, child) {
            final stats = productProvider.productStats;
            final isLoading = productProvider.isLoadingStats;
            if (productProvider.error != null) {
              // Affiche l'erreur de façon propre
              return ErrorDisplay(
                message: productProvider.error!,
                onRetry: () => productProvider.fetchProductStats(forceRefresh: true),
              );
            }
            return isLoading
                ? const Center(child: CircularProgressIndicator())
                : stats.isEmpty
                    ? Text('Aucune statistique disponible', style: TextStyle(color: Colors.grey[600]))
                    : GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 1.2,
                        children: [
                          StatsCard(
                            icon: Icons.inventory,
                            title: 'Total Produits',
                            subtitle: '${stats['totalProducts'] ?? '-'}',
                            color: Colors.blue,
                          ),
                          StatsCard(
                            icon: Icons.category,
                            title: 'Catégories',
                            subtitle: '${(stats['categoryStats'] as List?)?.length ?? '-'}',
                            color: Colors.purple,
                          ),
                          StatsCard(
                            icon: Icons.warning,
                            title: 'Stock Faible',
                            subtitle: '${stats['lowStockCount'] ?? '-'}',
                            color: Colors.orange,
                          ),
                          StatsCard(
                            icon: Icons.trending_up,
                            title: 'Valeur Totale',
                            subtitle: stats['totalValue'] != null
                                ? '${stats['totalValue']} FCFA'
                                : stats['totalQuantity'] != null
                                    ? '${stats['totalQuantity']} unités'
                                    : '-',
                            color: Colors.green,
                          ),
                        ],
                      );
          },
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Actions Rapides',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.productForm);
                },
                icon: const Icon(Icons.add),
                label: const Text('Nouveau Produit'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.stockHistory);
                },
                icon: const Icon(Icons.add_shopping_cart),
                label: const Text('Mouvement Stock'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentStockMovements(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Derniers Mouvements',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.stockHistory);
              },
              child: const Text('Voir tout'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Consumer<StockProvider>(
          builder: (context, stockProvider, child) {
            if (stockProvider.error != null) {
              return ErrorDisplay(
                message: stockProvider.error!,
                onRetry: () => stockProvider.loadStockHistory(forceRefresh: true),
              );
            }
            if (stockProvider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            final recentLogs = stockProvider.stockLogs.take(5).toList();

            if (recentLogs.isEmpty) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Icon(Icons.history, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 8),
                      Text(
                        'Aucun mouvement récent',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Column(
              children: recentLogs.map((log) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: log.typeColor.withValues(alpha: 0.1),
                      child: Icon(
                        log.type.toLowerCase() == 'in' ? Icons.add : Icons.remove,
                        color: log.typeColor,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      log.productName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${log.typeLabel} • ${log.quantity} unités',
                      style: TextStyle(
                        color: log.typeColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    trailing: Text(
                      '${log.createdAt.day}/${log.createdAt.month}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildLowStockAlerts(BuildContext context) {
    return Consumer<ProductProvider>(
      builder: (context, productProvider, child) {
        if (productProvider.isLoadingLowStock) {
          return const Center(child: CircularProgressIndicator());
        }

        final lowStockProducts = productProvider.lowStockProducts;
        
        if (lowStockProducts.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Alertes Stock Faible',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[700],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.productList);
                  },
                  child: const Text('Voir tout'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              color: Colors.orange.withValues(alpha: 0.1),
              child: Column(
                children: lowStockProducts.take(3).map((product) {
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.orange.withValues(alpha: 0.2),
                      child: Icon(
                        Icons.warning,
                        color: Colors.orange[700],
                      ),
                    ),
                    title: Text(
                      product.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${product.quantity} unités restantes',
                      style: TextStyle(
                        color: Colors.orange[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    trailing: Text(
                      product.category,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProductDetailScreen(product: product),
                        ),
                      );
                    },
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }
}

class ErrorDisplay extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  const ErrorDisplay({required this.message, this.onRetry, super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red[300], size: 64),
            const SizedBox(height: 16),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.red[700]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (onRetry != null)
              ElevatedButton(
                onPressed: onRetry,
                child: const Text('Réessayer'),
              ),
          ],
        ),
      ),
    );
  }
}
