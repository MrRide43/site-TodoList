# Todo App — TP Développement Web

Application de gestion de tâches multi-utilisateurs développée en HTML / CSS / JavaScript / PHP / MySQL.

---

## Stack technique

| Couche | Technologie |
|---|---|
| Structure | HTML5 sémantique |
| Apparence | CSS3 custom (sans framework) |
| Comportement client | JavaScript vanilla (fetch, querySelector) |
| Serveur | PHP 8+ |
| Base de données | MySQL (XAMPP) |
| Versioning | Git + GitHub |

---

## Fonctionnalités

### Authentification
- Inscription avec email + mot de passe
- Connexion / déconnexion
- Mots de passe hashés en base avec `password_hash()` (bcrypt)
- Redirection automatique vers la page de connexion si non connecté
- Chaque utilisateur ne voit que ses propres tâches

### Gestion des tâches
- Créer une tâche : titre, description (optionnelle), date d'échéance, priorité
- Marquer une tâche comme terminée / non terminée
- Modifier une tâche existante
- Supprimer une tâche
- Toutes les actions se font **sans rechargement de page** (fetch + JSON)

### Filtres et affichage
- Filtrer par statut : toutes / en cours / terminées
- Filtrer par priorité : toutes / basse / normale / haute
- Trier par : date de création, date d'échéance, priorité
- Mise en évidence visuelle des tâches dont la date d'échéance est dépassée
- Pagination côté serveur (LIMIT + OFFSET) : 10 / 25 / 50 / 100 tâches par page

---

## Prérequis

- [XAMPP](https://www.apachefriends.org/fr/index.html) (Apache + MySQL + PHP 8+)
- Un navigateur moderne (Chrome, Firefox, Edge)
- Git

---

## Installation et lancement

### 1. Cloner le dépôt

```bash
git clone https://github.com/TON_USERNAME/TON_REPO.git
```

Place le dossier dans `C:/xampp/htdocs/` :

```
C:/xampp/htdocs/
└── TP_site_blocNote/
    ├── index.html
    ├── api.php
    ├── app.js
    ├── style.css
    ├── config.php           ← à créer (voir étape 2)
    ├── config.example.php
    ├── database.sql
    └── README.md
```

### 2. Configurer la base de données

Copie `config.example.php` et renomme la copie en `config.php` :

```bash
cp config.example.php config.php
```

Paramètres XAMPP par défaut (rien à modifier normalement) :

```php
define('DB_HOST', 'localhost');
define('DB_USER', 'root');
define('DB_PASS', '');
define('DB_NAME', 'miniblog');
define('DB_PORT', '3306');
```

### 3. Importer la base de données

Le fichier `database.sql` contient **tout** : création de la base, des tables et les données de test. Une seule manipulation suffit.

- Démarre **Apache** et **MySQL** depuis le panneau XAMPP
- Ouvre **phpMyAdmin** : `http://localhost/phpmyadmin`
- Clique sur l'onglet **SQL** en haut (sans sélectionner de base au préalable)
- Colle le contenu de `database.sql` et clique **Exécuter**

Cela va automatiquement :
1. Créer la base de données `miniblog`
2. Créer les tables `users` et `tasks`
3. Insérer 2 comptes de test et 100 tâches variées

### 4. Lancer l'application

Ouvre ton navigateur et va sur :

```
http://localhost/TP_site_blocNote/index.html
```

---

## Comptes de test

| Email | Mot de passe | Nombre de tâches |
|---|---|---|
| alice@test.com | 123456 | 60 tâches |
| bob@test.com | 123456 | 40 tâches |

> Les tâches incluent toutes les priorités, certaines terminées et certaines en retard pour tester toutes les fonctionnalités de l'application.

---

## Structure des fichiers

```
TP_site_blocNote/
├── index.html            ← Interface utilisateur (HTML5 sémantique)
├── api.php               ← API REST PHP (JSON uniquement)
├── app.js                ← JavaScript vanilla (fetch, DOM)
├── style.css             ← CSS3 custom responsive
├── config.php            ← Identifiants BDD (non commité, dans .gitignore)
├── config.example.php    ← Modèle de config sans identifiants réels
├── database.sql          ← Script complet : BDD + tables + données de test
└── README.md             ← Ce fichier
```

---

## Structure de la base de données

### Table `users`
| Colonne | Type | Description |
|---|---|---|
| id | INT UNSIGNED | Clé primaire auto-incrémentée |
| email | VARCHAR(255) | Email unique de l'utilisateur |
| password | VARCHAR(255) | Hash bcrypt du mot de passe |
| created_at | DATETIME | Date de création du compte |

### Table `tasks`
| Colonne | Type | Description |
|---|---|---|
| id | INT UNSIGNED | Clé primaire auto-incrémentée |
| user_id | INT UNSIGNED | Clé étrangère → users.id (CASCADE DELETE) |
| title | VARCHAR(255) | Titre de la tâche (obligatoire) |
| description | TEXT | Description optionnelle |
| due_date | DATE | Date d'échéance (optionnelle) |
| priority | ENUM | low / normal / high |
| done | TINYINT(1) | 0 = en cours, 1 = terminée |
| created_at | DATETIME | Date de création |
| updated_at | DATETIME | Mise à jour automatique à chaque modification |

---

## Sécurité

- Mots de passe hashés avec `password_hash()` (bcrypt) — jamais stockés en clair
- Toutes les requêtes SQL utilisent des **requêtes préparées PDO** — aucune concaténation
- Vérification que chaque tâche appartient à l'utilisateur connecté avant toute modification
- Protection XSS côté JS avec `escapeHtml()` sur toutes les données affichées
- `config.php` absent du dépôt GitHub (listé dans `.gitignore`)

---

## Points techniques notables

- `api.php` retourne **uniquement du JSON**, jamais de HTML
- Zéro rechargement de page — tout passe par `fetch()`
- Pagination gérée **côté serveur** avec `LIMIT` et `OFFSET` SQL
- Sessions PHP pour maintenir l'authentification entre les requêtes
