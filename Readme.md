# GestLog

Application de gestion de demandes de prêt hypothécaire social, réalisée pour pratiquer une stack **Oracle (SQL et PL/SQL) + ASP.NET Core + React**.

> Projet d'apprentissage : les règles métier sont fictives et simplifiées.

## Fonctionnalités

- Consulter les demandeurs et leur éligibilité (au moins 3 enfants à charge).
- Créer une demande de prêt (achat, construction ou rénovation, jusqu'à 300 000 EUR, de 12 à 360 mois).
- Accepter ou refuser une demande en attente (un refus doit être motivé, une demande ne se traite qu'une fois).
- Historiser automatiquement chaque changement de statut.

## Stack technique

| Couche | Technologie |
| --- | --- |
| Base de données | Oracle AI Database 26ai Free (conteneur Docker), SQL et PL/SQL |
| API | ASP.NET Core minimal API (.NET 10), ODP.NET Core (`Oracle.ManagedDataAccess.Core`) |
| Interface | React + TypeScript (Vite) |

## Architecture

```
Navigateur (React, port 5173)
    |  fetch('/api/...')   -> le proxy Vite redirige vers l'API
    v
API ASP.NET Core (port 5080)
    Endpoints -> Repositories -> OracleConnectionFactory
    |  ODP.NET : appels du package pkg_prets
    v
Oracle Database Free (conteneur Docker, port 1521, service FREEPDB1)
    schéma FLW_DEV : tables, package pkg_prets, trigger d'historique
```

Choix principaux :

- **La logique métier est dans la base**, dans le package PL/SQL `pkg_prets`. L'API ne fait qu'appeler ses procédures.
- **L'API est organisée en couches** : les endpoints ne contiennent ni SQL ni référence à Oracle ; l'accès aux données est isolé dans des repositories injectés.
- **Les erreurs métier sont centralisées** : les erreurs Oracle `ORA-20001` à `ORA-20008` sont traduites en réponses HTTP 400 au format ProblemDetails (RFC 9457).
- **Aucun secret dans le dépôt** : le mot de passe de la base est fourni par les user secrets .NET en développement.

## Structure du dépôt

```
gestlog/
  db/
    01_schema.sql            tables, contraintes, index
    02_donnees.sql           données de test
    04a_pkg_prets_spec.sql   spécification du package
    04b_pkg_prets_body.sql   corps du package
    05_trigger.sql           trigger d'historique des statuts
    06_tests.sql             tests automatisés du package (33 vérifications)
  api/
    GestLog.Api/             API ASP.NET Core
  front/                     interface React (Vite)
```

---

## Prérequis

| Outil | Rôle | Vérification |
| --- | --- | --- |
| [Docker Desktop](https://www.docker.com/products/docker-desktop/) | Faire tourner Oracle | `docker --version` |
| [.NET SDK 10](https://dotnet.microsoft.com/download) | Compiler et lancer l'API | `dotnet --version` |
| [Node.js LTS](https://nodejs.org/) | Lancer le front | `node -v` |
| Client SQL : extension « Oracle SQL Developer » pour VS Code, ou SQL Developer | Exécuter les scripts | |
| Git | Cloner le dépôt | `git --version` |

Sous Windows, Docker Desktop nécessite WSL 2 et la virtualisation activée dans le BIOS. Prévoir une dizaine de Go d'espace disque pour l'image Oracle.

---

## Première installation

### 1. Cloner le dépôt

```bash
git clone <url-du-depot> gestlog
cd gestlog
```

### 2. Démarrer Oracle avec Docker

Télécharger l'image (une seule fois) :

```bash
docker pull container-registry.oracle.com/database/free:latest
```

Créer et lancer le conteneur, en choisissant un mot de passe administrateur (comptes `SYS` et `SYSTEM`).

PowerShell (Windows) :

```powershell
docker run -d --name oracle-free `
  -p 1521:1521 `
  -e ORACLE_PWD=<MOT_DE_PASSE_ADMIN> `
  -v oracle-data:/opt/oracle/oradata `
  container-registry.oracle.com/database/free:latest
```

Bash (macOS / Linux) : même commande, en remplaçant les accents graves `` ` `` par `\`.

| Option | Rôle |
| --- | --- |
| `-p 1521:1521` | Expose le port d'écoute Oracle |
| `-e ORACLE_PWD=...` | Mot de passe des comptes `SYS` et `SYSTEM` |
| `-v oracle-data:...` | Volume Docker : les données survivent à la suppression du conteneur |

Le premier démarrage prend quelques minutes. Attendre ce message dans les logs (Ctrl+C pour quitter) :

```bash
docker logs -f oracle-free
# ...
# DATABASE IS READY TO USE!
```

`docker ps` doit alors afficher le conteneur avec l'état `(healthy)`.

### 3. Créer l'utilisateur de l'application

Ouvrir SQL*Plus dans le conteneur, connecté en administrateur sur la base `FREEPDB1` :

```bash
docker exec -it oracle-free sqlplus system/<MOT_DE_PASSE_ADMIN>@//localhost:1521/FREEPDB1
```

Puis exécuter :

```sql
CREATE USER flw_dev IDENTIFIED BY "<MOT_DE_PASSE_FLW_DEV>"
  QUOTA UNLIMITED ON users;

GRANT CREATE SESSION, CREATE TABLE, CREATE VIEW, CREATE SEQUENCE,
      CREATE PROCEDURE, CREATE TRIGGER TO flw_dev;

exit
```

### 4. Créer le schéma

Connecté en **`flw_dev`**, exécuter les scripts du dossier `db/` **dans l'ordre**, en mode script :

1. `01_schema.sql`
2. `02_donnees.sql`
3. `04a_pkg_prets_spec.sql`
4. `04b_pkg_prets_body.sql`
5. `05_trigger.sql`
6. `06_tests.sql` : doit afficher `Résultat : 33 OK, 0 échec(s)`

Paramètres de connexion pour le client SQL :

| Paramètre | Valeur |
| --- | --- |
| Hôte | `localhost` |
| Port | `1521` |
| Type | **Service name** (et non SID) |
| Nom de service | `FREEPDB1` |
| Utilisateur | `flw_dev` |

**Variante sans client SQL**, en exécutant les scripts depuis le conteneur :

```bash
docker cp db oracle-free:/tmp/db
docker exec -it oracle-free sqlplus flw_dev/<MOT_DE_PASSE_FLW_DEV>@//localhost:1521/FREEPDB1
```

Puis, dans SQL*Plus : `@/tmp/db/01_schema.sql`, `@/tmp/db/02_donnees.sql`, etc., dans l'ordre ci-dessus.

Vérification : les objets du package doivent être valides.

```sql
SELECT object_name, object_type, status FROM user_objects WHERE object_name = 'PKG_PRETS';
-- PACKAGE et PACKAGE BODY : VALID
```

### 5. Configurer et lancer l'API

La chaîne de connexion **sans mot de passe** est dans `appsettings.Development.json` :

```json
"ConnectionStrings": {
  "Oracle": "User Id=flw_dev;Data Source=localhost:1521/FREEPDB1;"
}
```

Le mot de passe est fourni par les **user secrets**, stockés hors du dépôt :

```bash
cd api/GestLog.Api
dotnet user-secrets set "Oracle:Pwd" "<MOT_DE_PASSE_FLW_DEV>"
```

Dans Visual Studio : clic droit sur le projet, puis **Gérer les secrets utilisateur**.

Lancer l'API sur le port 5080 :

```bash
dotnet run --launch-profile http
```

Dans Visual Studio : sélectionner le profil **http** puis lancer (F5 ou Ctrl+F5).

Vérification : `http://localhost:5080/api/ping` doit renvoyer `{"utilisateur":"FLW_DEV", ...}`. Le fichier `GestLog.Api.http` contient des requêtes de test pour toutes les routes.

### 6. Lancer le front

```bash
cd front
npm install
npm run dev
```

Ouvrir http://localhost:5173. L'API doit être lancée : le proxy Vite lui transmet les appels `/api/...`.

---

## Relancer le projet au quotidien

Une fois l'installation faite, il suffit de :

1. Lancer **Docker Desktop**.
2. Démarrer la base :
   ```bash
   docker start oracle-free
   ```
3. Attendre l'état `(healthy)` avec `docker ps` (une à deux minutes).
4. Lancer l'API (profil http) et vérifier `http://localhost:5080/api/ping`.
5. Lancer le front : `npm run dev` dans `front/`.

Pour libérer la mémoire en fin de session :

```bash
docker stop oracle-free
```

Les données sont conservées : `docker stop` puis `docker start` ne perd rien.

## Commandes Docker utiles

| Besoin | Commande |
| --- | --- |
| Démarrer la base | `docker start oracle-free` |
| Arrêter la base | `docker stop oracle-free` |
| Voir l'état | `docker ps` (`docker ps -a` pour les conteneurs arrêtés) |
| Suivre les logs | `docker logs -f oracle-free` |
| Ouvrir SQL*Plus | `docker exec -it oracle-free sqlplus flw_dev/<MOT_DE_PASSE_FLW_DEV>@//localhost:1521/FREEPDB1` |
| Ouvrir SQL*Plus en administrateur | `docker exec -it oracle-free sqlplus / as sysdba` |
| Changer le mot de passe SYS/SYSTEM | `docker exec oracle-free ./setPassword.sh <NOUVEAU_MOT_DE_PASSE>` |
| Supprimer le conteneur (les données restent dans le volume) | `docker rm -f oracle-free` |
| Tout supprimer, données comprises | `docker rm -f oracle-free` puis `docker volume rm oracle-data` |

## Réinitialiser les données

L'API valide réellement chaque modification (ODP.NET fonctionne en autocommit). Pour revenir aux données de départ, connecté en `flw_dev` :

```sql
DROP TABLE historique_statut;
DROP TABLE demandes_pret;
DROP TABLE demandeurs;
```

Puis rejouer `01_schema.sql`, `02_donnees.sql` et `05_trigger.sql`. Le package n'a pas besoin d'être recréé, mais il doit être recompilé s'il apparaît `INVALID`.

---

## Routes de l'API

| Verbe | Route | Description | Succès |
| --- | --- | --- | --- |
| GET | `/api/ping` | Test de connexion à Oracle | 200 |
| GET | `/api/demandeurs` | Demandeurs et éligibilité | 200 |
| GET | `/api/demandes?statut=EN_ATTENTE` | Demandes, filtre facultatif par statut | 200 |
| POST | `/api/demandes` | Créer une demande | 201 |
| PUT | `/api/demandes/{id}/statut` | Accepter ou refuser une demande | 204 |

Une règle métier non respectée renvoie une **400** au format ProblemDetails :

```json
{ "status": 400, "title": "Règle métier non respectée",
  "detail": "Demandeur 3 est inéligible", "code": -20003 }
```

## Codes d'erreur métier

| Code | Situation |
| --- | --- |
| -20001 | Demandeur introuvable |
| -20002 | Montant invalide |
| -20003 | Demandeur inéligible |
| -20004 | Durée invalide |
| -20005 | Type de projet invalide |
| -20006 | Statut cible invalide |
| -20007 | Refus sans motif |
| -20008 | Demande inexistante ou déjà traitée |

## Dépannage

| Symptôme | Cause probable | Solution |
| --- | --- | --- |
| `ORA-12541` (no listener) | Conteneur arrêté | `docker start oracle-free`, attendre `(healthy)` |
| `ORA-12514` / `DBTS-02005` (service inconnu) | Nom de service incorrect, ou base pas encore prête | Vérifier `FREEPDB1` (Service name, pas SID) ; attendre `(healthy)` |
| `ORA-01017` | Utilisateur ou mot de passe incorrect | Vérifier les identifiants et les user secrets |
| `ORA-01005` ou « Mot de passe Oracle manquant » | Mot de passe absent de la configuration | `dotnet user-secrets set "Oracle:Pwd" "..."` |
| `ORA-50201` | Chaîne de connexion mal formée ou serveur injoignable | Lire l'exception interne ; vérifier `Data Source=localhost:1521/FREEPDB1` |
| Le conteneur ne démarre pas : port 1521 occupé | Une autre installation d'Oracle utilise le port | Arrêter les services Windows « Oracle… » |
| « Une erreur s'est produite lors de l'envoi de la demande » | L'API n'est pas lancée ou n'écoute pas sur 5080 | Lancer l'API avec le profil http |
| Les données ajoutées dans le client SQL sont invisibles pour l'API | `COMMIT` oublié | Exécuter `COMMIT;` |