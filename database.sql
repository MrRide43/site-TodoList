-- Création de la base de données si elle n'existe pas
CREATE DATABASE IF NOT EXISTS miniblog
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

-- On se positionne sur cette base
USE miniblog;

-- TABLE USERS

CREATE TABLE IF NOT EXISTS users (
  id         INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  email      VARCHAR(255) NOT NULL UNIQUE,
  password   VARCHAR(255) NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- TABLE TASKS

CREATE TABLE IF NOT EXISTS tasks (
  id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id     INT UNSIGNED NOT NULL,
  title       VARCHAR(255) NOT NULL,
  description TEXT,
  due_date    DATE,
  priority    ENUM('low','normal','high') NOT NULL DEFAULT 'normal',
  done        TINYINT(1) NOT NULL DEFAULT 0,
  created_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  CONSTRAINT fk_tasks_user
    FOREIGN KEY (user_id) REFERENCES users(id)
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


INSERT INTO users (email, password) VALUES
('alice@test.com', '$2y$10$qfRHWCzxXxS5rfpnljTLdOUAAuoZ1vYSDQboT9P6vMZvTAni4X.5u'),
('bob@test.com',   '$2y$10$qfRHWCzxXxS5rfpnljTLdOUAAuoZ1vYSDQboT9P6vMZvTAni4X.5u');

-- DONNÉES DE TEST — TÂCHES (100 tâches)
-- user_id 1 = alice (60 tâches)
-- user_id 2 = bob   (40 tâches)
-- Certaines dates sont dans le passé → tâches "en retard"

INSERT INTO tasks (user_id, title, description, due_date, priority, done, created_at) VALUES

-- ---- ALICE — high priority ----
(1, 'Préparer la réunion client',     'Préparer slides et démo',             '2025-03-01', 'high',   1, '2025-01-10 09:00:00'),
(1, 'Corriger bug de production',     'Erreur 500 sur /api/users',           '2025-04-01', 'high',   0, '2025-01-11 10:00:00'),
(1, 'Rendre le rapport annuel',       'Rapport complet avec graphiques',     '2025-03-15', 'high',   1, '2025-01-12 11:00:00'),
(1, 'Déployer la mise à jour',        'Déployer la v2.1 en production',      '2026-05-01', 'high',   0, '2025-01-13 08:00:00'),
(1, 'Revoir architecture BDD',        'Optimiser les index MySQL',           '2026-05-10', 'high',   0, '2025-01-14 09:30:00'),
(1, 'Fixer la faille de sécurité',    'XSS sur le formulaire de contact',    '2025-03-20', 'high',   1, '2025-01-15 10:00:00'),
(1, 'Mettre à jour les dépendances',  'npm audit fix',                       '2026-04-30', 'high',   0, '2025-01-16 14:00:00'),
(1, 'Préparer l entretien',           'Réviser algo et structures données',  '2025-02-28', 'high',   1, '2025-01-17 08:00:00'),
(1, 'Contacter le fournisseur',       'Négocier le nouveau contrat',         '2026-05-15', 'high',   0, '2025-01-18 09:00:00'),
(1, 'Audit de performance',           'Lighthouse score < 80 à corriger',    '2026-06-01', 'high',   0, '2025-01-19 10:00:00'),

-- ---- ALICE — normal priority ----
(1, 'Faire la veille techno',         'Lire les articles de la semaine',     '2026-04-28', 'normal', 0, '2025-02-01 09:00:00'),
(1, 'Mettre à jour le README',        'Ajouter les instructions d install',  '2026-04-29', 'normal', 0, '2025-02-02 10:00:00'),
(1, 'Refactoriser le module auth',    'Séparer login et register',           '2026-05-05', 'normal', 0, '2025-02-03 11:00:00'),
(1, 'Écrire les tests unitaires',     'Couvrir les fonctions critiques',     '2025-04-10', 'normal', 1, '2025-02-04 08:00:00'),
(1, 'Revoir le design mobile',        'Tester sur iPhone et Android',        '2026-05-20', 'normal', 0, '2025-02-05 09:00:00'),
(1, 'Nettoyer le code mort',          'Supprimer les fonctions inutilisées', '2026-04-30', 'normal', 0, '2025-02-06 10:00:00'),
(1, 'Documenter l API',               'Swagger ou Postman collection',       '2026-06-15', 'normal', 0, '2025-02-07 11:00:00'),
(1, 'Planifier le sprint suivant',    'Estimation des tickets Jira',         '2026-04-28', 'normal', 0, '2025-02-08 14:00:00'),
(1, 'Former la nouvelle recrue',      'Présenter l architecture du projet',  '2025-03-10', 'normal', 1, '2025-02-09 09:00:00'),
(1, 'Faire la démo hebdo',            'Présenter les nouvelles features',    '2026-04-28', 'normal', 0, '2025-02-10 10:00:00'),
(1, 'Configurer le CI/CD',            'GitHub Actions pipeline',             '2026-05-10', 'normal', 0, '2025-02-11 11:00:00'),
(1, 'Répondre aux issues GitHub',     'Trier et prioriser les issues',       '2026-04-29', 'normal', 0, '2025-02-12 08:00:00'),
(1, 'Faire la code review',           'Reviewer les PR en attente',          '2026-04-28', 'normal', 1, '2025-02-13 09:00:00'),
(1, 'Optimiser les images',           'Convertir en WebP et compresser',     '2026-05-25', 'normal', 0, '2025-02-14 10:00:00'),
(1, 'Mettre en place le monitoring',  'Sentry + alertes email',              '2026-06-01', 'normal', 0, '2025-02-15 11:00:00'),

-- ---- ALICE — low priority ----
(1, 'Trier les emails',               NULL,                                  '2026-04-30', 'low',    0, '2025-03-01 09:00:00'),
(1, 'Mettre à jour le portfolio',     'Ajouter les derniers projets',        '2026-06-30', 'low',    0, '2025-03-02 10:00:00'),
(1, 'Lire le livre Clean Code',       'Chapitres 5 à 10',                    NULL,         'low',    0, '2025-03-03 11:00:00'),
(1, 'Regarder la conf JSConf',        'Replay disponible sur YouTube',       NULL,         'low',    1, '2025-03-04 08:00:00'),
(1, 'Réorganiser le bureau',          NULL,                                  NULL,         'low',    0, '2025-03-05 09:00:00'),
(1, 'Sauvegarder les fichiers',       'Backup sur disque externe',           '2026-05-31', 'low',    0, '2025-03-06 10:00:00'),
(1, 'Mettre à jour le CV',            'Ajouter les nouvelles compétences',   NULL,         'low',    0, '2025-03-07 11:00:00'),
(1, 'Tester le nouveau framework',    'Essayer Bun.js sur un side project',  NULL,         'low',    0, '2025-03-08 14:00:00'),
(1, 'Écrire un article de blog',      'Sujet : les hooks React',             '2026-07-01', 'low',    0, '2025-03-09 09:00:00'),
(1, 'Classer les notes Obsidian',     NULL,                                  NULL,         'low',    1, '2025-03-10 10:00:00'),

-- ---- ALICE — tâches en retard (due_date passée + done=0) ----
(1, 'Payer la facture hébergement',   'OVH — facture de mars',               '2025-03-31', 'high',   0, '2025-03-01 09:00:00'),
(1, 'Rendre le devoir PHP',           'TP noté — todo list',                 '2025-04-15', 'high',   0, '2025-03-15 10:00:00'),
(1, 'Renouveler le nom de domaine',   'Expire le 1er avril',                 '2025-04-01', 'normal', 0, '2025-03-20 11:00:00'),
(1, 'Rappeler le client ABC',         'Devis en attente depuis 2 semaines',  '2025-04-05', 'normal', 0, '2025-03-25 09:00:00'),
(1, 'Mettre à jour les CGU',          'Nouvelles mentions légales RGPD',     '2025-03-25', 'low',    0, '2025-03-01 14:00:00'),

-- ---- ALICE — tâches terminées ----
(1, 'Créer la maquette Figma',        'Maquette validée par le client',      '2025-02-28', 'high',   1, '2025-01-05 09:00:00'),
(1, 'Installer XAMPP',                'Environnement de dev local',          '2025-01-15', 'normal', 1, '2025-01-02 10:00:00'),
(1, 'Créer le repo GitHub',           'Initialiser avec README et .gitignore','2025-01-20','normal', 1, '2025-01-03 11:00:00'),
(1, 'Définir le schéma BDD',          'Tables users et tasks',               '2025-01-25', 'high',   1, '2025-01-04 08:00:00'),
(1, 'Écrire le fichier api.php',      'Tous les endpoints CRUD',             '2025-02-10', 'high',   1, '2025-01-06 09:00:00'),
(1, 'Faire le design CSS',            'Style complet responsive',            '2025-02-20', 'normal', 1, '2025-01-07 10:00:00'),
(1, 'Tester l inscription',           'Vérifier hash bcrypt en BDD',         '2025-02-22', 'high',   1, '2025-01-08 11:00:00'),
(1, 'Tester la connexion',            'Session PHP fonctionnelle',           '2025-02-23', 'high',   1, '2025-01-09 14:00:00'),
(1, 'Vérifier la pagination',         '10/25/50/100 par page',               '2025-02-25', 'normal', 1, '2025-01-10 09:00:00'),
(1, 'Valider le responsive',          'Test sur mobile et tablette',         '2025-02-27', 'normal', 1, '2025-01-11 10:00:00'),

-- ---- BOB — high priority ----
(2, 'Finir le rapport de stage',      'À rendre avant vendredi',             '2025-04-18', 'high',   0, '2025-02-01 09:00:00'),
(2, 'Préparer la soutenance',         'Slides + répétition',                 '2026-05-20', 'high',   0, '2025-02-02 10:00:00'),
(2, 'Corriger les bugs critiques',    'Issues #12 #15 #18',                  '2025-03-30', 'high',   1, '2025-02-03 11:00:00'),
(2, 'Migrer vers PHP 8.2',            'Compatibilité à vérifier',            '2026-06-01', 'high',   0, '2025-02-04 08:00:00'),
(2, 'Mettre en prod le hotfix',       'Patch sécurité critique',             '2025-03-15', 'high',   1, '2025-02-05 09:00:00'),

-- ---- BOB — normal priority ----
(2, 'Préparer les examens',           'Révisions PHP et JavaScript',         '2026-05-25', 'normal', 0, '2025-03-01 09:00:00'),
(2, 'Rendre le TP todo list',         'Dépôt GitHub + démo',                 '2026-05-15', 'normal', 0, '2025-03-02 10:00:00'),
(2, 'Faire les exercices jQuery',     'TP du cours de vendredi',             '2025-04-12', 'normal', 1, '2025-03-03 11:00:00'),
(2, 'Lire le cours sur les API REST', 'Chapitre 4 du polycopié',             NULL,         'normal', 0, '2025-03-04 08:00:00'),
(2, 'Installer VS Code extensions',   'ESLint, Prettier, PHP Intelephense',  NULL,         'normal', 1, '2025-03-05 09:00:00'),
(2, 'Faire la maquette du projet',    'Wireframe sur Figma ou papier',       '2026-04-30', 'normal', 0, '2025-03-06 10:00:00'),
(2, 'Tester les requêtes préparées',  'PDO avec bindValue',                  '2026-04-29', 'normal', 0, '2025-03-07 11:00:00'),
(2, 'Commenter le code PHP',          'Ajouter les commentaires manquants',  '2026-04-28', 'normal', 0, '2025-03-08 14:00:00'),
(2, 'Revoir les sessions PHP',        'Cours sur $_SESSION et cookies',      NULL,         'normal', 1, '2025-03-09 09:00:00'),
(2, 'Préparer les données de test',   'Script SQL avec données réalistes',   '2026-04-28', 'normal', 0, '2025-03-10 10:00:00'),

-- ---- BOB — low priority ----
(2, 'Regarder tuto Docker',           NULL,                                  NULL,         'low',    0, '2025-04-01 09:00:00'),
(2, 'Configurer Git global',          'user.name et user.email',             NULL,         'low',    1, '2025-04-02 10:00:00'),
(2, 'Créer compte LinkedIn',          NULL,                                  NULL,         'low',    0, '2025-04-03 11:00:00'),
(2, 'Rejoindre Discord dev',          'Serveur JavaScript francophone',      NULL,         'low',    0, '2025-04-04 08:00:00'),
(2, 'Tester Tailwind CSS',            'Comparaison avec CSS custom',         NULL,         'low',    0, '2025-04-05 09:00:00'),

-- ---- BOB — tâches en retard ----
(2, 'Rendre exercice SQL',            'Exercice joins et sous-requêtes',     '2025-03-20', 'high',   0, '2025-03-10 09:00:00'),
(2, 'Répondre au formateur',          'Question sur le projet TP',           '2025-04-10', 'normal', 0, '2025-03-25 10:00:00'),
(2, 'Pousser les commits',            'GitHub doit être à jour',             '2025-04-12', 'high',   0, '2025-04-01 11:00:00'),

-- ---- BOB — tâches terminées ----
(2, 'Créer la BDD MySQL',             'Tables users et tasks créées',        '2025-02-15', 'high',   1, '2025-02-01 09:00:00'),
(2, 'Tester phpMyAdmin',              'Connexion et navigation OK',          '2025-02-16', 'normal', 1, '2025-02-02 10:00:00'),
(2, 'Écrire le config.php',           'Constantes BDD définies',             '2025-02-17', 'normal', 1, '2025-02-03 11:00:00'),
(2, 'Ajouter le .gitignore',          'config.php ignoré par Git',           '2025-02-18', 'normal', 1, '2025-02-04 08:00:00'),
(2, 'Créer config.example.php',       'Modèle sans vrais identifiants',      '2025-02-19', 'normal', 1, '2025-02-05 09:00:00'),
(2, 'Installer XAMPP',                'Apache + MySQL + PHP 8',              '2025-01-20', 'normal', 1, '2025-01-15 10:00:00'),
(2, 'Faire le premier commit',        'Initial commit sur GitHub',           '2025-01-22', 'normal', 1, '2025-01-16 11:00:00');