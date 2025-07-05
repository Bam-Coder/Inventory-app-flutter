# 📦 Inventory Management App

Une application Flutter moderne et complète pour la gestion d'inventaire, conçue pour les petites et moyennes entreprises.

## ✨ Fonctionnalités

### 🔐 Authentification
- Connexion/Inscription sécurisée
- Gestion des rôles (Utilisateur/Admin)
- Session persistante
- Changement de mot de passe

### 📊 Dashboard
- Vue d'ensemble en temps réel
- Statistiques d'inventaire
- Activité récente
- Navigation intuitive

### 🏷️ Gestion des Produits
- CRUD complet des produits
- Recherche avancée
- Filtrage par catégorie
- Gestion des stocks faibles
- Photos des produits

### 📈 Gestion des Stocks
- Mouvements d'entrée/sortie
- Historique complet
- Ajustements de stock
- Alertes automatiques

### 📋 Rapports & Statistiques
- Rapports détaillés
- Graphiques interactifs
- Export en CSV
- Analyses par période

### 👨‍💼 Administration
- Gestion des utilisateurs
- Logs d'audit
- Statistiques globales
- Paramètres système

### ⚙️ Paramètres
- Notifications push
- Seuils d'alerte
- Thème personnalisable
- Cache configurable

## 🏗️ Architecture

```
lib/
├── core/                 # Services et configuration
│   ├── config/          # Constantes et environnement
│   ├── services/        # Services partagés
│   ├── utils/           # Utilitaires
│   └── errors/          # Gestion d'erreurs
├── features/            # Fonctionnalités métier
│   ├── auth/           # Authentification
│   ├── products/       # Gestion produits
│   ├── stock/          # Gestion stocks
│   ├── dashboard/      # Tableau de bord
│   ├── admin/          # Administration
│   ├── reports/        # Rapports
│   ├── export/         # Export
│   └── profile/        # Profil utilisateur
└── shared/             # Composants partagés
    ├── widgets/        # Widgets réutilisables
    ├── themes/         # Thèmes
    └── navigation/     # Navigation
```

## 🚀 Installation

### Prérequis
- Flutter 3.19+
- Dart 3.3+
- Android Studio / VS Code
- Backend API (Node.js/Express/MongoDB)

### Étapes d'installation

1. **Cloner le projet**
```bash
git clone <repository-url>
cd inventory_app
```

2. **Installer les dépendances**
```bash
flutter pub get
```

3. **Configurer l'environnement**
```bash
# Copier le fichier d'exemple
cp lib/core/config/env.dart.example lib/core/config/env.dart
# Modifier les variables selon votre environnement
```

4. **Lancer l'application**
```bash
flutter run
```

## ⚙️ Configuration

### Variables d'environnement

```dart
// lib/core/config/env.dart
class Environment {
  static const String apiBaseUrl = 'http://your-api-url:port';
  static const String appName = 'Inventory Management';
  static const String appVersion = '1.0.0';
  static const bool isDebug = true;
  static const bool enableLogging = true;
  static const int apiTimeout = 30;
  static const int cacheExpiration = 300;
}
```

### Backend API

L'application nécessite une API backend avec les endpoints suivants :

- `POST /auth/login` - Connexion
- `POST /auth/register` - Inscription
- `GET /auth/profile` - Profil utilisateur
- `GET /products` - Liste des produits
- `POST /products` - Créer un produit
- `PUT /products/:id` - Modifier un produit
- `DELETE /products/:id` - Supprimer un produit
- `GET /stock/logs` - Historique des stocks
- `POST /stock/in` - Entrée de stock
- `POST /stock/out` - Sortie de stock
- `GET /admin/users` - Liste des utilisateurs (admin)
- `GET /admin/stats` - Statistiques globales (admin)

## 🧪 Tests

### Tests unitaires
```bash
flutter test
```

### Tests d'intégration
```bash
flutter test integration_test/
```

### Tests de widgets
```bash
flutter test test/widget_test.dart
```

## 📱 Build

### Android
```bash
flutter build apk --release
```

### iOS
```bash
flutter build ios --release
```

### Web
```bash
flutter build web --release
```

## 🔧 Développement

### Structure du code
- **Clean Architecture** avec séparation des couches
- **Provider Pattern** pour la gestion d'état
- **Repository Pattern** pour l'accès aux données
- **Service Layer** pour la logique métier

### Bonnes pratiques
- Code commenté et documenté
- Gestion d'erreurs centralisée
- Logging structuré
- Tests unitaires
- Code review obligatoire

### Performance
- Cache intelligent
- Lazy loading
- Optimisation des images
- Gestion mémoire efficace

## 🐛 Débogage

### Logs
```dart
import 'package:inventory_app/core/utils/logger.dart';

AppLogger.debug('Message de debug');
AppLogger.info('Information');
AppLogger.warning('Avertissement');
AppLogger.error('Erreur', exception);
AppLogger.success('Succès');
```

### Mode debug
```bash
flutter run --debug
```

## 📄 Licence

Ce projet est sous licence MIT. Voir le fichier `LICENSE` pour plus de détails.

## 🤝 Contribution

1. Fork le projet
2. Créer une branche feature (`git checkout -b feature/AmazingFeature`)
3. Commit les changements (`git commit -m 'Add some AmazingFeature'`)
4. Push vers la branche (`git push origin feature/AmazingFeature`)
5. Ouvrir une Pull Request

## 📞 Support

Pour toute question ou problème :
- Ouvrir une issue sur GitHub
- Contacter l'équipe de développement
- Consulter la documentation technique

---

**Développé avec ❤️ par l'équipe Inventory Management**
