<?php

/*
    HEADER 

    on déclare le type de contenu de la réponse (ici du JSON)
    on démarre une session AVANT tout echo ou header
*/ 
session_start();

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');

/*
    Connexion à la base de données
*/

require_once 'config.php';

try {
    $dsn = 'mysql:host=' . DB_HOST . ';dbname=' . DB_NAME . ';port=' . DB_PORT. ';charset=utf8mb4';
    $pdo = new PDO($dsn, DB_USER, DB_PASS, [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        PDO::ATTR_EMULATE_PREPARES => false,
    ]);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['error' => 'Erreur de connexion à la base de données']);
    exit;
}

/*
    Récuprération des données envoyées
*/

$methode = $_SERVER['REQUEST_METHOD'];
$body = json_decode(file_get_contents('php://input'), true) ?? [];

/*php://input permet de récupérer le body brut, json_decode le transforme en tableau PHP */


// fusionne: si les données qui viennent de $_POST ou du body JSON

$data = array_merge($_GET, $_POST, $body);
$action = $data['action'] ?? '';


/* ====================================
    BLOC 2 - authentification
==================================== */

// inscription

if ($action === 'register') {

    $email = trim($data['email'] ?? '');
    $password = $data['password'] ?? '';

    if (empty($email) || empty($password)) {
        http_response_code(400);
        echo json_encode(['error' => 'Email et mot de passe requis']);
        exit;
    }
    
     if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
        http_response_code(400);
        echo json_encode(['error' => 'Email invalide']);
        exit;
    }

    if (strlen($password) < 6) {
        http_response_code(400);
        echo json_encode(['error' => 'Le mot de passe doit contenir au moins 6 caractères']);
        exit;
    }

    // Vérifier si l'email existe déjà
    $stmt = $pdo->prepare('SELECT id FROM users WHERE email = :email');
    $stmt->execute(['email' => $email]);

    if ($stmt->fetch()) {
        http_response_code(409);
        echo json_encode(['error' => 'Cet email est déjà utilisé']);
        exit;
    }

    // Hash du mot de passe
    $hash = password_hash($password, PASSWORD_BCRYPT);

    // Insertion de l'utilisateur
    $stmt = $pdo->prepare('INSERT INTO users (email, password) VALUES (:email, :password)');
    $stmt->execute(['email' => $email, 'password' => $hash]);

    $userId = $pdo->lastInsertId();

    // Connecter direct après l'inscription
    $_SESSION['user_id'] = $userId;
    $_SESSION['email'] = $email;

    http_response_code(201);
    echo json_encode([
        'succes' => true,
        'user' => [
            'id' => $userId,
            'email' => $email
        ]
    ]);
    exit;
}

// connexion (login)

if ($action === 'login') {

    $email = trim($data['email'] ?? '');
    $password = $data['password'] ?? '';

    if (empty($email) || empty($password)) {
        http_response_code(400);
        echo json_encode(['error' => 'Email et mot de passe requis']);
        exit;
    }

    // Récupérer l'utilisateur
    $stmt = $pdo->prepare('SELECT id, password FROM users WHERE email = :email');
    $stmt->execute(['email' => $email]);
    $user = $stmt->fetch();

    if (!$user || !password_verify($password, $user['password'])) {
        http_response_code(401);
        echo json_encode(['error' => 'Email ou mot de passe incorrect']);
        exit;
    }

    // Connecter l'utilisateur
    $_SESSION['user_id'] = $user['id'];
    $_SESSION['email'] = $email;

    http_response_code(200);
    echo json_encode([
        'succes' => true,
        'user' => [
            'id' => $user['id'],
            'email' => $email
        ]
    ]);
    exit;
}

// déconnexion (logout)

if ($action === 'logout') {
    session_destroy();

    echo json_encode(['succes' => true]);
    exit;
}

/*vérifier si on est connecté */
if ($action === 'check') {
    if (isset($_SESSION['user_id'])) {
        echo json_encode([
            'connecte' => true,
            'user' => [
                'id' => $_SESSION['user_id'],
                'email' => $_SESSION['email']
            ]
        ]);
    } else {
        echo json_encode(['connecte' => false]);
    }
    exit;
}

/*  Gestion des tâches 
    Sécurité toutes les actions dans les tâches necessitent d'être connecté. 
    on vérifie la session avant de faire quoi que ce soit.
*/

$userId = $_SESSION['user_id'] ?? null;

function requireAuth($userId) {
    if (!$userId) {
        http_response_code(401);
        echo json_encode(['error' => 'Non connecté']);
        exit;
    }
}

// lire les tâches (avec filtres + pagination)

if ($action === 'getTasks') {
    requireAuth($userId);

    // Récupération des filtres envoyés par JS  
    $statut = $data['statut'] ?? 'toutes';
    $priorite = $data['priorite'] ?? 'toutes';
    $tri = $data['tri'] ?? 'created_at';
    $page = max(1, intval($data['page'] ?? 1));
    $parPage = intval($data['par_page'] ?? 10);
    
    //Sécurise le tri (jamais de données dans le SQL directement)
    $triAutorises = ['created_at', 'due_date', 'priority'];
    if (!in_array($tri, $triAutorises)) {
        $tri = 'created_at';
    }

    // pareil pour par_page Sécurise
    $parPageAutorises = [10, 20, 50, 100];
    if (!in_array($parPage, $parPageAutorises)) {
        $parPage = 10;
    }
    
    //construction du WHERE dynamique
    $conditions = ['user_id = :user_id'];
    $params = ['user_id' => $userId];

    if ($statut === 'en_cours') {
        $conditions[] = 'done = "0"';
    } elseif ($statut === 'terminees') {
        $conditions[] = 'done = "1"';
    }

    if ($priorite !== 'toutes') {
        $conditions[] = 'priority = :priority';
        $params['priority'] = $priorite;
    }

    $where = implode(' AND ', $conditions);

    // compter le total pour la pagination
    $stmtCount = $pdo->prepare("SELECT COUNT(*) FROM tasks WHERE $where");
    $stmtCount->execute($params);
    $total = $stmtCount->fetchColumn();

    // calculer le OFFSET
    $offset = ($page - 1) * $parPage;

    // requête principale avec LIMIT et OFFSET
    $sql = "SELECT * FROM tasks WHERE $where ORDER BY $tri DESC LIMIT :limit OFFSET :offset";
    $stmt = $pdo->prepare($sql);

    //on bind les paramètres normaux
    foreach ($params as $key => $value) {
        $stmt->bindValue(':' . $key, $value);
    }

    //LIMIT et OFFSET doivent être bindés comme entiers
    $stmt->bindValue(':limit', $parPage, PDO::PARAM_INT);
    $stmt->bindValue(':offset', $offset, PDO::PARAM_INT);

    $stmt->execute();
    $tasks = $stmt->fetchAll();

    echo json_encode([
        'succes' => true,
        'tasks' => $tasks,
        'total' => $total,
        'page' => $page,
        'par_page' => $parPage,
        'nb_pages' => ceil($total / $parPage)
    ]);
    exit;
}

/* =====================

Création d'une tâche 

========================*/

if ($action === 'createTask') {
    requireAuth($userId);

    $title = trim($data['title'] ?? '');
    $description = trim($data['description'] ?? '');
    $due_date = $data['due_date'] ?? null;
    $priority = $data['priority'] ?? 'normal';

    //Validation
    if (empty($title)) {
        http_response_code(400);
        echo json_encode(['error' => 'Le titre est requis']);
        exit;
    }

    $prioritesAutorisees = ['low', 'normal', 'high'];
    if (!in_array($priority, $prioritesAutorisees)) {
        $priority = 'normal';
    }

    $due_date = empty($due_date) ? null : $due_date;

    $stmt = $pdo->prepare('INSERT INTO tasks (user_id, title, description, due_date, priority) VALUES (:user_id, :title, :description, :due_date, :priority)');
    $stmt->execute([
        'user_id' => $userId,
        'title' => $title,
        'description' => $description,
        'due_date' => $due_date,
        'priority' => $priority
    ]);

    $id = $pdo->lastInsertId();

    http_response_code(201);
    echo json_encode([
        'succes' => true,
        'task' => [
            'id' => $id,
            'title' => $title,
            'description' => $description,
            'due_date' => $due_date,
            'priority' => $priority,
            'done' => 0,
        ]
    ]);
    exit;
}

/* Modifier une tâche */

if ($action === 'updateTask') {
    requireAuth($userId);

    $id = intval($data['id'] ?? 0);
    $title = trim($data['title'] ?? '');
    $description = trim($data['description'] ?? '');
    $due_date = $data['due_date'] ?? null;
    $priority = $data['priority'] ?? 'normal';

    if ($id <= 0 || empty($title)) {
        http_response_code(400);
        echo json_encode(['error' => 'ID & titre requis']);
        exit;
    }

    // Vérifier que la tâche appartient à l'utilisateur
    $stmt = $pdo->prepare('SELECT id FROM tasks WHERE id = :id AND user_id = :user_id');
    $stmt->execute(['id' => $id, 'user_id' => $userId]);
    if (!$stmt->fetch()) {
        http_response_code(403);
        echo json_encode(['error' => 'Tâche introuvable ou accès refusé']);
        exit;
    }

    $due_date = empty($due_date) ? null : $due_date;

    $stmt = $pdo->prepare('UPDATE tasks SET title = :title, description = :description, due_date = :due_date, priority = :priority WHERE id = :id AND user_id = :user_id');
    $stmt->execute([
        'id' => $id,
        'user_id' => $userId,
        'title' => $title,
        'description' => $description,
        'due_date' => $due_date,
        'priority' => $priority
    ]);

    echo json_encode(['succes' => true]);
    exit;
}

/* Supprimer une tâche */

if ($action === 'deleteTask') {
    requireAuth($userId);

    $id = intval($data['id'] ?? 0);

    if ($id <= 0) {
        http_response_code(400);
        echo json_encode(['error' => 'ID Invalide']);
        exit;
    }

    // Vérifier que la tâche appartient à l'utilisateur
    $stmt = $pdo->prepare('SELECT id FROM tasks WHERE id = :id AND user_id = :user_id');
    $stmt->execute(['id' => $id, 'user_id' => $userId]);
    if (!$stmt->fetch()) {
        http_response_code(403);
        echo json_encode(['error' => 'Tâche introuvable ou accès refusé']);
        exit;
    }

    $stmt = $pdo->prepare('DELETE FROM tasks WHERE id = :id AND user_id = :user_id');
    $stmt->execute(['id' => $id, 'user_id' => $userId]);

    echo json_encode(['succes' => true]);
    exit;
}

/* cocher / décocher une tâche (toggle*/

if ($action === 'toggleTask') {
    requireAuth($userId);

    $id = intval($data['id'] ?? 0);

    if ($id <= 0) {
        http_response_code(400);
        echo json_encode(['error' => 'ID Invalide']);
        exit;
    }

    // Récupére l'état actuel
    $stmt = $pdo->prepare('SELECT done FROM tasks WHERE id = :id AND user_id = :user_id');
    $stmt->execute(['id' => $id, 'user_id' => $userId]);
    $task = $stmt->fetch();

    if (!$task) {
        http_response_code(403);
        echo json_encode(['error' => 'Tâche introuvable ou accès refusé']);
        exit;
    }

    //invertion de l'état : 0 devient 1, 1 devient 0
    $newDone = $task['done'] ? 0 : 1;

    $stmt = $pdo->prepare('UPDATE tasks SET done = :done WHERE id = :id AND user_id = :user_id');
    $stmt-> execute([
        'done' => $newDone,
        'id' => $id,
        'user_id' => $userId
    ]);

    echo json_encode(['succes' => true, 'done' => $newDone]);
    exit;
}

http_response_code(400);
echo json_encode(['erreur' => 'Action manquante ou inconnu.']);
