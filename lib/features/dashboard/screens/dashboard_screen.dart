import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../features/auth/controllers/auth_provider.dart';
import '../../../features/products/controllers/product_provider.dart';
import '../../../features/stock/controllers/stock_provider.dart';
import '../../dashboard/widgets/stats_card.dart';
import '../../../shared/navigation/app_routes.dart';
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
  bool _isInitialized = false;
  
  final List<Widget> _screens = [
    const DashboardContent(),
    const ProductListScreen(),
    const StockHistoryScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    if (_isInitialized) return;
    
    try {
      // Charger les données une seule fois au démarrage
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      final stockProvider = Provider.of<StockProvider>(context, listen: false);
      
      // Charger les produits d'abord
      await productProvider.loadProducts();
      
      // Puis charger les statistiques et stocks faibles
      await Future.wait([
        productProvider.fetchProductStats(),
        productProvider.fetchLowStockProducts(),
        stockProvider.loadStockHistory(),
      ]);
      
      _isInitialized = true;
    } catch (e) {
      AppLogger.error('Erreur lors de l\'initialisation du dashboard', e);
    }
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
      floatingActionButton: _currentIndex == 1
          ? _buildFloatingActionButton()
          : null,
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
  bool _isRefreshing = false;

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;

    return RefreshIndicator(
      onRefresh: () async {
        if (_isRefreshing) return;
        _isRefreshing = true;
        
        try {
          // Rechargement optimisé avec délai entre les requêtes
          final productProvider = Provider.of<ProductProvider>(context, listen: false);
          final stockProvider = Provider.of<StockProvider>(context, listen: false);
          
          await productProvider.loadProducts(forceRefresh: true);
          await Future.delayed(const Duration(milliseconds: 500));
          
          await Future.wait([
            productProvider.fetchProductStats(forceRefresh: true),
            productProvider.fetchLowStockProducts(),
            stockProvider.loadStockHistory(forceRefresh: true),
          ]);
        } finally {
          _isRefreshing = false;
        }
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
                      backgroundColor: log.typeColor.withOpacity(0.1),
                      child: Icon(
                        log.type.toLowerCase() == 'in' ? Icons.add : Icons.remove,
                        color: log.typeColor,
                        size: 20,
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
                    subtitle: Text(
                      '${log.typeLabel} • ${log.quantity} unités',
                      style: TextStyle(
                        color: log.typeColor,
                        fontWeight: FontWeight.bold,
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
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Alertes Stock Faible',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[700],
                ),
              ),
              const SizedBox(height: 16),
              const Center(child: CircularProgressIndicator()),
            ],
          );
        }

        final lowStockProducts = productProvider.lowStockProducts;
        
        if (lowStockProducts.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Alertes Stock Faible',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
              const SizedBox(height: 16),
              Card(
                color: Colors.green.withValues(alpha: 0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green[700]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Aucun produit en stock faible',
                          style: TextStyle(
                            color: Colors.green[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange[700], size: 24),
                    const SizedBox(width: 8),
                    Text(
                      'Alertes Stock Faible',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[700],
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange[700],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${lowStockProducts.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
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
            ...lowStockProducts.take(3).map((product) {
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                color: Colors.orange.withValues(alpha: 0.05),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.orange.withValues(alpha: 0.1),
                    child: Icon(
                      Icons.warning,
                      color: Colors.orange[700],
                      size: 20,
                    ),
                  ),
                  title: Text(
                    product.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Stock: ${product.quantity} ${product.unit} (Seuil: ${product.reorderThreshold})',
                    style: TextStyle(
                      color: Colors.orange[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  trailing: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.productForm, arguments: product);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    child: const Text('Réapprovisionner'),
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }
}

class ErrorDisplay extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const ErrorDisplay({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.red.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(Icons.error_outline, color: Colors.red[700], size: 48),
            const SizedBox(height: 8),
            Text(
              'Erreur: $message',
              style: TextStyle(
                color: Colors.red[700],
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[700],
                foregroundColor: Colors.white,
              ),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}
