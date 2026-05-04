// Varaible global

let currentPage = 1;
let currentParPage = 10;
let currentStatut = "toutes";
let currentPriorite = "toutes";
let currentTri = "created_at";

// Fonction utilitaire pour éviter le fetch à chaque fois

async function api(action, data = {}) {

    // on fusionne l'action avec les données si on appelle api {email, password} le body envoyé sera {action: "login", email: "email", password: "password"}
    const body = JSON.stringify({ action, ...data });

    const response = await fetch("api.php", {
        method: "POST",
        headers: {
            // on dit au serveur du JSON sinon php ne serait comment lire le body.
            "Content-Type": "application/json"
        },
        body: body
    });

    // on converti la réponse en objet Javascript. c'est l'équivalent de JSON.parse mais adapté pour le fetch 
    const json = await response.json();
    // on retourne le status HTTP, pour vérifié la requête
    return {ok: response.ok, status: response.status, data: json};
}

// Fonction utilitaire pour afficher un message d'erreur dans un élément précis

function showError(elementId, message) {
    const el = document.getElementById(elementId);
    el.textContent = message;
    el.style.display = "block";
}

function hideError(elementId) {
    const el = document.getElementById(elementId);
    el.style.display = "none";
}

// Bloc 1 Démarrage de l'application quand elle est complétement chargé 

document.addEventListener("DOMContentLoaded", () => {
    init();
});

async function init() {
    // on vérifie si l'utilisateur est connecté
    const result = await api("check");

    if (result.data.connecte) {
        // si connecté on affiche l'application
        showApp(result.data.user);
    } else {
        //pas connecté: page de connexion
        showAuth();
    }

    // on met les écouteurs d'événements
    setupAuthListeners();
    setupTaskListeners();
    setupFilterListeners();
}

// Bloc 2 partie authentification

function showAuth() {
    document.getElementById("authSection").style.display = "flex";
    document.getElementById("appSection").style.display = "none";
}

function showApp(user) {
    document.getElementById("authSection").style.display = "none";
    document.getElementById("appSection").style.display = "block";
    document.getElementById("userEmail").textContent = user.email;
    loadTasks();
}

function setupAuthListeners() {
    // onglets Login/register
    document.querySelectorAll('.tab-btn').forEach(btn => {
        btn.addEventListener('click', () => {
            const tab = btn.dataset.tab; //login ou register

            //Retire le classe active des onglets
            document.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'));
            //Mettre la classe sur active quand l'onglet est cliqué
            btn.classList.add('active');

            //Affiche le bon formulaire
            document.getElementById('loginForm').style.display = tab === 'login' ? 'block' : 'none';
            document.getElementById('registerForm').style.display = tab === 'register' ? 'block' : 'none';

            hideError('authError');
        });
    });

    //Formulaire de connexion
    document.getElementById("loginForm").addEventListener("submit", async (e) => {
        // "prevenDefault" va empêcher le comportement par defaut qui va recharger la page cette ligne permet de tout faire sans rechargement 
        e.preventDefault();
        hideError('authError');

        const email = document.getElementById("loginEmail").value;
        const password = document.getElementById("loginPassword").value;

        const result = await api("login", { email, password });

        if (result.ok) {
            showApp(result.data.user);
        } else {
            showError('authError', result.data.error);
        }
    });

    //Formulaire d'inscription
    document.getElementById("registerForm").addEventListener("submit", async (e) => {
        e.preventDefault();
        hideError('authError');

        const email = document.getElementById("registerEmail").value;
        const password = document.getElementById("registerPassword").value;

        const result = await api("register", { email, password });

        if (result.ok) {
            showApp(result.data.user);
        } else {
            showError('authError', result.data.error);
        }
    });

    //Bouton Déconnexion
    document.getElementById("logoutBtn").addEventListener("click", async () => {
        await api("logout");
        showAuth();
    });
}

// Bloc 3 Chargement & affichage des tâches

async function loadTasks() {
    document.getElementById('tasksLoading').style.display = 'block';
    document.getElementById('tasksList').innerHTML = '';
    document.getElementById('tasksEmpty').style.display = 'none';
    document.getElementById('pagination').style.display = 'none';

    const result = await api("getTasks", {
        statut: currentStatut,
        priorite: currentPriorite,
        tri: currentTri,
        page: currentPage,
        par_page: currentParPage
    });

    document.getElementById('tasksLoading').style.display = 'none';

    if (!result.ok) {
        showError('tasksError', 'Erreur lors du chargement des tâches');
        return;
    }

    const { tasks, total, page, par_page, nb_pages } = result.data;

    if (tasks.length === 0) {
        document.getElementById('tasksEmpty').style.display = 'block';
        return;
    }

    // on va génèrer le HTML de chaque tâche et l'inserer dans la page
    document.getElementById('tasksList').innerHTML = tasks.map(renderTasks).join('');

    //pagination
    if (nb_pages > 1) {
        updatePagination(page, nb_pages, total);
    }
}

function renderTasks(task) {
    // on construit du HTML d'une tâche sous forme de chaine. permettent d'écrire du HTML sur plusieurs lignes avec des variables

    //Va Vérifié si la date d'échéance est dépassée pour l'afficher 2025-04-15 
    const today = new Date().toISOString().split('T')[0];
    const isOverdue = task.due_date && task.due_date < today && task.done == 0;
    const isDone = task.done == 1;

    /*
    On insère le CSS dynamiquement pour: 
    task-card : toujours présent
    done: si la tâche est terminée
    overdue: si la tâche est dépassée 
    */

    //permet de supprimer les chaine vides du tableau 
    const classes = ['task-card', isDone ? 'done' : '', isOverdue ? 'overdue' : '', `priority-${task.priority}`].filter(Boolean).join(' ');

    const priorityLabel = {
        low: 'Basse',
        normal: 'Normale',
        high: 'Haute'
    }[task.priority];

    const dueDateHtml = task.due_date ? `<span class="task-due ${isOverdue ? 'overdue-text' : ''}">
            ${task.due_date} ${isOverdue ? 'En retard' : ''}
        </span>` : '';
        
    return `
        <div class="${classes}" data-id="${task.id}" data-due-date="${task.due_date || ''}" data-priority="${task.priority}">

            <div class="task-header">
                <input 
                    type="checkbox" 
                    class="task-checkbox"
                    data-id="${task.id}"
                    ${isDone ? 'checked' : ''}
                >
                <h3 class="task-title">${escapeHtml(task.title)}</h3>
                <span class="task-priority priority-badge-${task.priority}">
                    ${priorityLabel}
                </span>
            </div>

            ${task.description 
                ? `<p class="task-description">${escapeHtml(task.description)}</p>` 
                : ''}

            <div class="task-footer">
                ${dueDateHtml}
                <div class="task-actions">
                    <button class="btn-edit" data-id="${task.id}">
                        Modifier
                    </button>
                    <button class="btn-delete" data-id="${task.id}">
                        Supprimer
                    </button>
                </div>
            </div>

        </div>
    `;
}

// fonction contre les injections XSS permet de convertir si un utilisateur met des balises <scirpt> ça va le convertir en texte HTML
function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

function updatePagination(page, nbpages, total) {
    document.getElementById('pagination').style.display = 'flex';
    document.getElementById('pageInfo').textContent = `Page ${page} sur ${nbpages} (${total} tâches)`;

    document.getElementById('prevPage').disabled = page <= 1;
    document.getElementById('nextPage').disabled = page >= nbpages;
}

function setupFilterListeners() {
    ["filterStatut", "filterPriorite", "filterTri", "filterParPage"].forEach(id => {
        document.getElementById(id).addEventListener("change", () => {
            currentStatut = document.getElementById("filterStatut").value;
            currentPriorite = document.getElementById("filterPriorite").value;
            currentTri = document.getElementById("filterTri").value;
            currentParPage = parseInt(document.getElementById("filterParPage").value);
            currentPage = 1;
            loadTasks();
        });
    });

    // pagination
    document.getElementById("prevPage").addEventListener("click", () => {
        if (currentPage > 1) {
            currentPage--;
            loadTasks();
        }
    });

    document.getElementById("nextPage").addEventListener("click", () => {
        currentPage++;
        loadTasks();
    });
}

// bloc 4 CRUD des tâches

function setupTaskListeners() {
    //Forumulaire (ajout ou modification)
    document.getElementById("taskForm").addEventListener("submit", async (e) => {
        e.preventDefault();

        const id = document.getElementById("taskId").value;
        const title = document.getElementById("taskTitle").value;
        const description = document.getElementById("taskDescription").value;
        const due_date = document.getElementById("taskDueDate").value;
        const priority = document.getElementById("taskPriority").value;

        let result;

        if (id) {
            // si l'id est rempli on est en mode Modif
            result = await api("updateTask", { id, title, description, due_date, priority });
        } else {
            // sinon on est en mode création
            result = await api("createTask", { title, description, due_date, priority });
        }

        if (result.ok) {
            resetTaskForm();
            loadTasks(); //permet de recharger la liste 
        } else {
            alert(result.data.error);
        }
    });

    // Bouton pour annuler l'édition
    document.getElementById("cancelEditBtn").addEventListener("click", () => {
        resetTaskForm();
    });

    /*
    pour les boutons dans la liste on va écouter sur le conteneur parent et vérifié quel élément est cliqué (c'est la délégation d'événement)
    car les boutons n'existe pas encore vu qu'il sont crée dynamiquement pas le renderTask
    */

    document.getElementById("tasksList").addEventListener("click", async (e) => {
        
        //partie Modifier 
        if (e.target.classList.contains("btn-edit")) {
            const id = e.target.dataset.id;
            startEditTask(id);
        }

        //partie Supprimer
        if (e.target.classList.contains("btn-delete")) {
            const id = e.target.dataset.id;

            if (confirm("Supprimer cette tâche ?")) {
                const result = await api("deleteTask", { id });

                if (result.ok) {
                    loadTasks();
                } else {
                    alert(result.data.erreur);
                }
            }
        }
    });

    // Délégation pour les toggle

    document.getElementById("tasksList").addEventListener("change", async (e) => {
        if (e.target.classList.contains("task-checkbox")) {
            const id = e.target.dataset.id;

            const result = await api("toggleTask", { id });

            if (result.ok) {
                loadTasks();
            } else {
                alert(result.data.erreur);
            }
        }
    });
}

function startEditTask(id) {
    const card = document.querySelector(`.task-card[data-id="${id}"]`);

    console.log("card trouvé :", card);
    console.log("due-date brute :", card.dataset.dueDate);
    console.log("priority brute :", card.dataset.priority);

    //on remplie le formulaire avec les données de la tâche
    document.getElementById("taskId").value = id;
    document.getElementById("taskTitle").value = card.querySelector(".task-title").textContent;
    document.getElementById("taskDescription").value = card.querySelector(".task-description")?.textContent ?? '';
    document.getElementById('taskDueDate').value = card.dataset.dueDate.trim();
    document.getElementById('taskPriority').value = card.dataset.priority;

    //Changer le texte du bouton pour afficher Annuler
    document.getElementById("taskSubmitBtn").textContent = "enregistrer les modifications";
    document.getElementById("cancelEditBtn").style.display = "inline-block";
    
    //Scroll vers le formulaire
    document.getElementById("taskForm").scrollIntoView({ behavior: "smooth" });
}

function resetTaskForm() {
    document.getElementById("taskForm").reset();
    document.getElementById("taskId").value = "";
    document.getElementById("taskSubmitBtn").textContent = "Ajouter la tâche";
    document.getElementById("cancelEditBtn").style.display = "none";
}