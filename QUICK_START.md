# 🚀 Guide de Démarrage Rapide

Ce guide vous permettra de démarrer l'application d'inventaire en moins de 10 minutes.

## 📋 Prérequis

- ✅ Flutter SDK 3.3+
- ✅ Node.js 16+
- ✅ MongoDB installé et démarré
- ✅ Android Studio / VS Code

## ⚡ Installation Express

### 1. Backend (API)

```bash
# Aller dans le dossier backend
cd "Inventory_Mapi - Copy"

# Installer les dépendances
npm install

# Copier le fichier d'environnement
cp env.example .env

# Démarrer MongoDB (si pas déjà fait)
mongod

# Démarrer l'API
npm run dev
```

✅ **L'API est maintenant accessible sur `http://localhost:5003`**

### 2. Frontend (Flutter)

```bash
# Retourner au dossier principal
cd ..

# Installer les dépendances Flutter
flutter pub get

# Lancer l'application
flutter run
```

✅ **L'application Flutter est maintenant lancée !**

## 🔐 Première Connexion

1. **Créer un compte admin** :
   - Ouvrir `http://localhost:5003/api-docs` dans votre navigateur
   - Tester l'endpoint `POST /auth/register`
   - Utiliser ces données :
   ```json
   {
     "name": "Admin",
     "email": "admin@example.com",
     "password": "password123",
     "businessName": "Ma Boutique"
   }
   ```

2. **Se connecter à l'app** :
   - Utiliser les mêmes identifiants dans l'app Flutter
   - Vous serez automatiquement connecté

## 📱 Test Rapide

### Ajouter un produit
1. Aller dans l'onglet "Produits"
2. Cliquer sur le bouton "+"
3. Remplir le formulaire :
   - Nom : "Ordinateur portable"
   - Description : "Ordinateur gaming"
   - Quantité : 10
   - Seuil : 5
   - Unité : "pièces"
   - Catégorie : "Électronique"
   - Fournisseur : "TechCorp"

### Gérer le stock
1. Aller dans l'onglet "Stock"
2. Cliquer sur le bouton "+"
3. Ajouter une sortie de stock :
   - Produit : "Ordinateur portable"
   - Quantité : 3
   - Type : "Sortie"
   - Note : "Vente client"

### Voir les rapports
1. Aller dans le menu latéral
2. Cliquer sur "Rapports"
3. Voir les statistiques en temps réel

## 🔧 Configuration Rapide

### Changer l'URL de l'API

Si vous utilisez un appareil physique ou un émulateur différent :

```dart
// lib/core/config/constants.dart
class Constants {
  // Pour émulateur Android
  static const String apiBaseUrl = 'http://10.0.2.2:5003';
  
  // Pour appareil physique (remplacer par votre IP)
  // static const String apiBaseUrl = 'http://192.168.1.100:5003';
  
  // Pour iOS Simulator
  // static const String apiBaseUrl = 'http://localhost:5003';
}
```

### Variables d'environnement Backend

```env
# .env
PORT=5003
MONGODB_URI=mongodb://localhost:27017/inventory
JWT_SECRET=mon-secret-super-securise
NODE_ENV=development
```

## 🐛 Dépannage

### Problème de connexion API
```bash
# Vérifier que l'API fonctionne
curl http://localhost:5003/health

# Vérifier MongoDB
mongo --eval "db.runCommand('ping')"
```

### Problème Flutter
```bash
# Nettoyer le cache
flutter clean
flutter pub get

# Vérifier la configuration
flutter doctor
```

### Problème de build
```bash
# Mettre à jour Flutter
flutter upgrade

# Vérifier les dépendances
flutter pub outdated
flutter pub upgrade
```

## 📊 Fonctionnalités à Tester

### ✅ Authentification
- [ ] Inscription
- [ ] Connexion
- [ ] Auto-login
- [ ] Changement de mot de passe

### ✅ Produits
- [ ] Ajouter un produit
- [ ] Modifier un produit
- [ ] Supprimer un produit
- [ ] Rechercher des produits

### ✅ Stock
- [ ] Entrée de stock
- [ ] Sortie de stock
- [ ] Ajustement de stock
- [ ] Historique des mouvements

### ✅ Rapports
- [ ] Dashboard
- [ ] Statistiques
- [ ] Export CSV
- [ ] Alertes stock faible

### ✅ Administration
- [ ] Gestion des utilisateurs
- [ ] Logs d'audit
- [ ] Statistiques globales

## 🎯 Prochaines Étapes

1. **Personnaliser** : Modifier les couleurs et thèmes
2. **Ajouter des données** : Créer des produits et mouvements de stock
3. **Configurer les alertes** : Définir vos seuils de stock faible
4. **Tester l'export** : Exporter vos données en CSV
5. **Explorer l'API** : Consulter la documentation Swagger

## 📞 Support

- 📖 **Documentation complète** : `README.md`
- 🔧 **API Documentation** : `http://localhost:5003/api-docs`
- 🐛 **Problèmes** : Créer une issue GitHub

---

**🎉 Félicitations ! Votre application d'inventaire est prête à l'emploi !** 