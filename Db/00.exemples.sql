SET SERVEROUTPUT ON

-- ---------------------------------------------------------------------
-- || DATE || --
-- ---------------------------------------------------------------------

-- Littéral de date ANSI (le plus sûr)
SELECT * FROM demandes_pret WHERE date_demande >= DATE '2026-01-01';

-- Conversion texte <-> date : on précise TOUJOURS le format
SELECT TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI') FROM DUAL;   -- 04/11/2026 14:30
SELECT TO_DATE('15/03/2026', 'DD/MM/YYYY') FROM DUAL;

-- Ignorer l'heure
SELECT * FROM demandes_pret WHERE TRUNC(date_demande) = TRUNC(SYSDATE);

-- Arithmétique : + 1 = un jour de plus ; soustraire deux dates = un nombre de jours
SELECT SYSDATE + 7, TRUNC(SYSDATE - date_demande) AS age_jours FROM demandes_pret;
SELECT ADD_MONTHS(SYSDATE, 3), TRUNC(MONTHS_BETWEEN(SYSDATE, DATE '2026-01-01')) FROM DUAL;

-- ---------------------------------------------------------------------
-- || PAGINATION || --
-- ---------------------------------------------------------------------

-- Version ancienne ROWNUM avec sous-requête :
SELECT * FROM (
   SELECT * FROM demandes_pret ORDER BY montant DESC
) WHERE ROWNUM <= 3;

-- Version moderne équivalente :
SELECT * FROM demandes_pret ORDER BY montant DESC FETCH FIRST 3 ROWS ONLY;

-- ---------------------------------------------------------------------
-- || SEQUENCE & IDENTITY || --
-- ---------------------------------------------------------------------

-- Méthode moderne (12c+)
CREATE TABLE exemple (
   id  NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
   nom VARCHAR2(50)
);
INSERT INTO exemple (nom) VALUES ('Test identity');
SELECT * FROM exemple;

-- Méthode historique : une séquence ; très fréquente en maintenance
CREATE TABLE exemple_ancien (
   id  NUMBER PRIMARY KEY,
   nom VARCHAR2(50)
);
CREATE SEQUENCE seq_exemple START WITH 1 INCREMENT BY 1;
INSERT INTO exemple_ancien (id, nom) VALUES (seq_exemple.NEXTVAL, 'Test');
SELECT seq_exemple.CURRVAL FROM DUAL;   -- dernière valeur obtenue dans MA session
SELECT * FROM exemple_ancien;

-- Nettoyage
DROP TABLE exemple PURGE;
DROP TABLE exemple_ancien PURGE;
DROP SEQUENCE seq_exemple;              -- une séquence se supprime avec DROP SEQUENCE

-- ---------------------------------------------------------------------
-- || MERGE || --
-- ---------------------------------------------------------------------

MERGE INTO demandeurs d
USING (SELECT 'marie.lambert@mail.be' AS email, 4 AS nb_enfants FROM DUAL) s
   ON (d.email = s.email)
 WHEN MATCHED THEN
      UPDATE SET d.nb_enfants = s.nb_enfants
 WHEN NOT MATCHED THEN
      INSERT (nom, prenom, email, nb_enfants)
      VALUES ('Lambert', 'Marie', s.email, s.nb_enfants);

SELECT * FROM demandeurs WHERE email = 'marie.lambert@mail.be';
ROLLBACK;

-- ---------------------------------------------------------------------
-- || PL/SQL - Bases || --
-- ---------------------------------------------------------------------

DECLARE                                   -- 1. déclarations (facultatif)
   v_nom      VARCHAR2(50);
   v_compteur NUMBER := 0;                -- := pour affecter
   c_max      CONSTANT NUMBER := 300000;
BEGIN                                     -- 2. instructions (obligatoire)
   SELECT COUNT(*) INTO v_compteur FROM demandeurs;
   DBMS_OUTPUT.PUT_LINE('Nombre de demandeurs : ' || v_compteur);
EXCEPTION                                 -- 3. gestion des erreurs (facultatif)
   WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('Erreur : ' || SQLERRM);
END;
/

-- ---------------------------------------------------------------------
-- || PL/SQL - SELECT INTO || --
-- ---------------------------------------------------------------------

DECLARE
   v_dem demandeurs%ROWTYPE;
BEGIN
   SELECT * INTO v_dem FROM demandeurs WHERE id = 1;
   DBMS_OUTPUT.PUT_LINE(v_dem.prenom || ' ' || v_dem.nom
                        || ' : ' || v_dem.nb_enfants || ' enfants');
END;
/

-- ---------------------------------------------------------------------
-- || PL/SQL - Structures de contrôle || --
-- ---------------------------------------------------------------------

DECLARE
   v_nb_enfants NUMBER := 4;
   v_categorie  VARCHAR2(20);
   v_statut     VARCHAR2(15) := 'REFUSEE';
   v_libelle    VARCHAR2(20);
   v_compteur   NUMBER := 0;
BEGIN
   -- IF / ELSIF / ELSE  (attention : ELSIF, sans E)
   IF v_nb_enfants >= 3 THEN
      v_categorie := 'FAMILLE_NOMBREUSE';
   ELSIF v_nb_enfants > 0 THEN
      v_categorie := 'FAMILLE';
   ELSE
      v_categorie := 'SANS_ENFANT';
   END IF;
   DBMS_OUTPUT.PUT_LINE('Catégorie : ' || v_categorie);

   -- CASE en instruction
   CASE v_statut
      WHEN 'ACCEPTEE' THEN v_libelle := 'Acceptée';
      WHEN 'REFUSEE'  THEN v_libelle := 'Refusée';
      ELSE                 v_libelle := 'En attente';
   END CASE;
   DBMS_OUTPUT.PUT_LINE('Libellé : ' || v_libelle);

   -- Boucle FOR (i est déclaré implicitement)
   FOR i IN 1 .. 3 LOOP
      DBMS_OUTPUT.PUT_LINE('FOR : ' || i);
   END LOOP;

   -- Boucle WHILE
   WHILE v_compteur < 5 LOOP
      v_compteur := v_compteur + 1;
   END LOOP;
   DBMS_OUTPUT.PUT_LINE('Après WHILE : ' || v_compteur);

   -- Boucle simple avec sortie conditionnelle
   LOOP
      v_compteur := v_compteur - 1;
      EXIT WHEN v_compteur = 0;
   END LOOP;
   DBMS_OUTPUT.PUT_LINE('Après LOOP : ' || v_compteur);
END;
/

-- ---------------------------------------------------------------------
-- || PL/SQL - Curseurs || --
-- ---------------------------------------------------------------------

-- Curseur implicite : SQL%ROWCOUNT (à capturer juste après l'instruction)
DECLARE
   v_nb NUMBER;
BEGIN
   UPDATE demandes_pret SET statut = 'ACCEPTEE' WHERE id = 42 AND statut = 'EN_ATTENTE';
   v_nb := SQL%ROWCOUNT;
   DBMS_OUTPUT.PUT_LINE(v_nb || ' ligne(s) modifiée(s)');
   IF v_nb = 0 THEN
      RAISE_APPLICATION_ERROR(-20005, 'Demande introuvable ou déjà traitée');
   END IF;
EXCEPTION
   WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('Erreur attendue : ' || SQLERRM);
END;
/

-- Boucle FOR sur curseur : la forme à privilégier
BEGIN
   FOR r IN (SELECT nom, prenom, nb_enfants FROM demandeurs ORDER BY nom) LOOP
      DBMS_OUTPUT.PUT_LINE(r.nom || ' ' || r.prenom || ' (' || r.nb_enfants || ')');
   END LOOP;
END;
/

-- Curseur explicite
DECLARE
   CURSOR c_demandes(p_statut VARCHAR2) IS
      SELECT id, montant FROM demandes_pret WHERE statut = p_statut;
   v_id      demandes_pret.id%TYPE;
   v_montant demandes_pret.montant%TYPE;
BEGIN
   OPEN c_demandes('EN_ATTENTE');
   LOOP
      FETCH c_demandes INTO v_id, v_montant;
      EXIT WHEN c_demandes%NOTFOUND;
      DBMS_OUTPUT.PUT_LINE(v_id || ' : ' || v_montant);
   END LOOP;
   CLOSE c_demandes;
END;
/

-- SYS_REFCURSOR : renvoyer un résultat à l'application
CREATE OR REPLACE PROCEDURE lister_demandeurs(p_result OUT SYS_REFCURSOR) AS
BEGIN
   OPEN p_result FOR
      SELECT id, nom, prenom FROM demandeurs ORDER BY nom;
END;
/

-- Lire le curseur depuis le script (commandes SQL*Plus / SQLcl)
VARIABLE rc REFCURSOR
EXEC lister_demandeurs(:rc)
PRINT rc

-- ---------------------------------------------------------------------
-- || PL/SQL - Exceptions || --
-- ---------------------------------------------------------------------

DECLARE
   v_nom demandeurs.nom%TYPE;
   v_nb  demandeurs.nb_enfants%TYPE;
   e_sans_enfant EXCEPTION;               -- exception métier déclarée par nous
BEGIN
   SELECT nom, nb_enfants INTO v_nom, v_nb FROM demandeurs WHERE id = 999;
   IF v_nb = 0 THEN
      RAISE e_sans_enfant;
   END IF;
EXCEPTION
   WHEN NO_DATA_FOUND THEN
      DBMS_OUTPUT.PUT_LINE('Aucun demandeur avec cet id');
   WHEN e_sans_enfant THEN
      DBMS_OUTPUT.PUT_LINE('Cas métier');
   WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(SQLCODE || ' : ' || SQLERRM);
      RAISE;                              -- on journalise, puis on relance
END;
/

-- ---------------------------------------------------------------------
-- || PL/SQL - Procédures, fonctions et packages || --
-- ---------------------------------------------------------------------

CREATE OR REPLACE FUNCTION mensualite(
   p_montant IN NUMBER,
   p_mois    IN NUMBER
) RETURN NUMBER IS
BEGIN
   RETURN ROUND(p_montant / p_mois, 2);   -- calcul volontairement simplifié (sans intérêts)
END mensualite;
/

SELECT id, montant, mensualite(montant, duree_mois) AS mensualite FROM demandes_pret;

CREATE OR REPLACE PACKAGE pkg_exemple AS          -- SPÉCIFICATION : le contrat public
   c_taux CONSTANT NUMBER := 0.03;
   FUNCTION double(p_x IN NUMBER) RETURN NUMBER;
   PROCEDURE saluer(p_nom IN VARCHAR2);
END pkg_exemple;
/

CREATE OR REPLACE PACKAGE BODY pkg_exemple AS     -- CORPS : l'implémentation
   FUNCTION double(p_x IN NUMBER) RETURN NUMBER IS
   BEGIN
      RETURN p_x * 2;
   END double;

   PROCEDURE saluer(p_nom IN VARCHAR2) IS
   BEGIN
      DBMS_OUTPUT.PUT_LINE('Bonjour ' || p_nom);
   END saluer;
END pkg_exemple;
/

-- Appel : nom_package.nom_sous_programme
BEGIN
   pkg_exemple.saluer('Marie');
   DBMS_OUTPUT.PUT_LINE('Double de 21 : ' || pkg_exemple.double(21));
END;
/

-- ---------------------------------------------------------------------
-- || PL/SQL - Trigger || --
-- ---------------------------------------------------------------------

CREATE OR REPLACE TRIGGER trg_demandeurs_maj_nom
BEFORE INSERT OR UPDATE ON demandeurs
FOR EACH ROW
BEGIN
   :NEW.nom := UPPER(TRIM(:NEW.nom));     -- en BEFORE, on peut modifier :NEW
   IF INSERTING THEN
      :NEW.date_creation := SYSDATE;
   END IF;
END;
/

-- Test : le nom est nettoyé et mis en majuscules automatiquement
UPDATE demandeurs SET nom = '  dubois  ' WHERE id = 1;
SELECT id, nom FROM demandeurs WHERE id = 1;
ROLLBACK;

-- Exemple uniquement : à supprimer pour ne pas perturber le projet
DROP TRIGGER trg_demandeurs_maj_nom;

-- ---------------------------------------------------------------------
-- || PL/SQL - Performance et BULK COLLECT / FORALL || --
-- ---------------------------------------------------------------------

DECLARE
   TYPE t_ids IS TABLE OF demandes_pret.id%TYPE;
   v_ids t_ids;
BEGIN
   SELECT id BULK COLLECT INTO v_ids          -- chargement en masse
     FROM demandes_pret
    WHERE statut = 'EN_ATTENTE' AND date_demande < SYSDATE - 365;

   FORALL i IN 1 .. v_ids.COUNT                 -- un seul aller-retour pour tous les UPDATE
      UPDATE demandes_pret
         SET statut = 'REFUSEE', motif_refus = 'Demande expirée'
       WHERE id = v_ids(i);

   DBMS_OUTPUT.PUT_LINE(v_ids.COUNT || ' demande(s) expirée(s)');
END;
/
ROLLBACK;

-- ---------------------------------------------------------------------
-- Nettoyage facultatif des objets d'exemple
-- ---------------------------------------------------------------------
-- DROP FUNCTION mensualite;
-- DROP PROCEDURE lister_demandeurs;
-- DROP PACKAGE pkg_exemple;