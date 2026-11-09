-- =====================================================================
-- Tests automatisés du package pkg_prets
-- À exécuter en mode SCRIPT (Run Script), connectée en flw_dev.
--
-- Codes d'erreur testés (ceux du corps du package) :
--   -20001  Demandeur introuvable
--   -20002  Montant invalide
--   -20003  Demandeur inéligible
--   -20004  Durée invalide
--   -20005  Type de projet invalide
--   -20006  Statut cible invalide
--   -20007  Refus sans motif
--   -20008  Demande inexistante ou déjà traitée
--
-- Le script crée ses propres demandes de test et se termine par un
-- ROLLBACK : les données restent intactes.
-- Prérequis : les demandeurs 1 (3 enfants), 2 (4 enfants) et 3 (1 enfant) de 02_donnees.sql.
-- =====================================================================

SET SERVEROUTPUT ON

DECLARE
    -- Compteurs
    v_ok        PLS_INTEGER := 0;
    v_ko        PLS_INTEGER := 0;

    -- Variables de travail
    v_id        demandes_pret.id%TYPE;     -- demande créée en T2.1, acceptée en T3.1
    v_id2       demandes_pret.id%TYPE;     -- demande refusée en T3.7
    v_id3       demandes_pret.id%TYPE;     -- demande acceptée avec un motif en T3.9
    v_id_tmp    demandes_pret.id%TYPE;     -- pour les appels censés échouer
    v_type      demandes_pret.type_projet%TYPE;
    v_statut    demandes_pret.statut%TYPE;
    v_motif     demandes_pret.motif_refus%TYPE;
    v_nb        NUMBER;
    v_attendu   NUMBER;
    v_ordre_ok  BOOLEAN;
    v_filtre_ok BOOLEAN;

    -- ---------------------------------------------------------------
    -- Petites procédures d'aide (déclarées APRÈS les variables)
    -- ---------------------------------------------------------------
    PROCEDURE succes (p_test VARCHAR2) IS
    BEGIN
        v_ok := v_ok + 1;
        DBMS_OUTPUT.PUT_LINE('[OK]    ' || p_test);
    END succes;

    PROCEDURE echec (p_test VARCHAR2, p_detail VARCHAR2) IS
    BEGIN
        v_ko := v_ko + 1;
        DBMS_OUTPUT.PUT_LINE('[ECHEC] ' || p_test || '  ->  ' || p_detail);
    END echec;

    -- Vérifie que l'erreur obtenue porte le code attendu
    PROCEDURE verifier_erreur (p_test VARCHAR2, p_attendu NUMBER,
                               p_code NUMBER, p_msg VARCHAR2) IS
    BEGIN
        IF p_code = p_attendu THEN
            succes(p_test || ' (' || p_attendu || ')');
        ELSE
            echec(p_test, 'attendu ' || p_attendu || ', obtenu : ' || p_msg);
        END IF;
    END verifier_erreur;

    -- Vérifie qu'une valeur obtenue est égale à la valeur attendue (NULL compris)
    PROCEDURE verifier_egal (p_test VARCHAR2, p_attendu VARCHAR2, p_obtenu VARCHAR2) IS
    BEGIN
        IF p_obtenu = p_attendu OR (p_obtenu IS NULL AND p_attendu IS NULL) THEN
            succes(p_test);
        ELSE
            echec(p_test, 'attendu "' || p_attendu || '", obtenu "' || p_obtenu || '"');
        END IF;
    END verifier_egal;

    -- Parcourt le REF CURSOR de lister_demandes : renvoie le nombre de lignes,
    -- et indique si le tri et le filtre sont respectés
    FUNCTION compter_curseur (p_statut    VARCHAR2,
                              p_ordre_ok  OUT BOOLEAN,
                              p_filtre_ok OUT BOOLEAN) RETURN NUMBER IS
        v_cur    SYS_REFCURSOR;
        r_id     demandes_pret.id%TYPE;
        r_dem    VARCHAR2(200);
        r_mont   demandes_pret.montant%TYPE;
        r_duree  demandes_pret.duree_mois%TYPE;
        r_type   demandes_pret.type_projet%TYPE;
        r_statut demandes_pret.statut%TYPE;
        r_date   demandes_pret.date_demande%TYPE;
        r_motif  demandes_pret.motif_refus%TYPE;
        v_prec   DATE;
        v_n      NUMBER := 0;
    BEGIN
        p_ordre_ok  := TRUE;
        p_filtre_ok := TRUE;
        pkg_prets.lister_demandes(p_statut, v_cur);
        LOOP
            FETCH v_cur INTO r_id, r_dem, r_mont, r_duree, r_type, r_statut, r_date, r_motif;
            EXIT WHEN v_cur%NOTFOUND;
            v_n := v_n + 1;
            IF v_prec IS NOT NULL AND r_date > v_prec THEN
                p_ordre_ok := FALSE;              -- une date plus récente après une plus ancienne
            END IF;
            IF p_statut IS NOT NULL AND r_statut <> p_statut THEN
                p_filtre_ok := FALSE;             -- une ligne d'un autre statut
            END IF;
            v_prec := r_date;
        END LOOP;
        CLOSE v_cur;
        RETURN v_n;
    END compter_curseur;

BEGIN
    -- =================================================================
    DBMS_OUTPUT.PUT_LINE('=== 1. est_eligible ===');
    -- =================================================================

    BEGIN
        verifier_egal('T1.1 Demandeur 1 (3 enfants) éligible', '1', pkg_prets.est_eligible(1));
    EXCEPTION WHEN OTHERS THEN echec('T1.1', SQLERRM);
    END;

    BEGIN
        verifier_egal('T1.2 Demandeur 3 (1 enfant) non éligible', '0', pkg_prets.est_eligible(3));
    EXCEPTION WHEN OTHERS THEN echec('T1.2', SQLERRM);
    END;

    BEGIN
        v_nb := pkg_prets.est_eligible(999);
        echec('T1.3 Demandeur inexistant', 'aucune erreur levée');
    EXCEPTION WHEN OTHERS THEN
        verifier_erreur('T1.3 Demandeur inexistant', -20001, SQLCODE, SQLERRM);
    END;

    -- =================================================================
    DBMS_OUTPUT.PUT_LINE('=== 2. creer_demande ===');
    -- =================================================================

    -- Cas nominal : le type en minuscules doit être enregistré en majuscules
    BEGIN
        pkg_prets.creer_demande(1, 120000, 240, 'achat', v_id);
        SELECT type_projet, statut INTO v_type, v_statut
          FROM demandes_pret WHERE id = v_id;
        verifier_egal('T2.1a Id renvoyé dans p_id', 'OUI',
                      CASE WHEN v_id IS NOT NULL THEN 'OUI' ELSE 'NON' END);
        verifier_egal('T2.1b Type enregistré en majuscules', 'ACHAT', v_type);
        verifier_egal('T2.1c Statut initial EN_ATTENTE', 'EN_ATTENTE', v_statut);
    EXCEPTION WHEN OTHERS THEN echec('T2.1 Création nominale', SQLERRM);
    END;

    -- Valeur limite : le montant maximum lui-même est autorisé
    BEGIN
        pkg_prets.creer_demande(2, pkg_prets.c_montant_max, 300, 'CONSTRUCTION', v_id_tmp);
        succes('T2.2 Montant égal au maximum accepté');
    EXCEPTION WHEN OTHERS THEN echec('T2.2 Montant égal au maximum', SQLERRM);
    END;

    BEGIN
        pkg_prets.creer_demande(1, pkg_prets.c_montant_max + 1, 240, 'ACHAT', v_id_tmp);
        echec('T2.3 Montant > maximum', 'aucune erreur levée');
    EXCEPTION WHEN OTHERS THEN
        verifier_erreur('T2.3 Montant > maximum', -20002, SQLCODE, SQLERRM);
    END;

    BEGIN
        pkg_prets.creer_demande(1, 0, 240, 'ACHAT', v_id_tmp);
        echec('T2.4 Montant à 0', 'aucune erreur levée');
    EXCEPTION WHEN OTHERS THEN
        verifier_erreur('T2.4 Montant à 0', -20002, SQLCODE, SQLERRM);
    END;

    BEGIN
        pkg_prets.creer_demande(1, NULL, 240, 'ACHAT', v_id_tmp);
        echec('T2.5 Montant NULL', 'aucune erreur levée');
    EXCEPTION WHEN OTHERS THEN
        verifier_erreur('T2.5 Montant NULL', -20002, SQLCODE, SQLERRM);
    END;

    BEGIN
        pkg_prets.creer_demande(3, 50000, 120, 'ACHAT', v_id_tmp);
        echec('T2.6 Demandeur inéligible', 'aucune erreur levée');
    EXCEPTION WHEN OTHERS THEN
        verifier_erreur('T2.6 Demandeur inéligible', -20003, SQLCODE, SQLERRM);
    END;

    BEGIN
        pkg_prets.creer_demande(999, 50000, 120, 'ACHAT', v_id_tmp);
        echec('T2.7 Demandeur inexistant', 'aucune erreur levée');
    EXCEPTION WHEN OTHERS THEN
        verifier_erreur('T2.7 Demandeur inexistant', -20001, SQLCODE, SQLERRM);
    END;

    BEGIN
        pkg_prets.creer_demande(1, 50000, 6, 'ACHAT', v_id_tmp);
        echec('T2.8 Durée trop courte', 'aucune erreur levée');
    EXCEPTION WHEN OTHERS THEN
        verifier_erreur('T2.8 Durée trop courte', -20004, SQLCODE, SQLERRM);
    END;

    BEGIN
        pkg_prets.creer_demande(1, 50000, NULL, 'ACHAT', v_id_tmp);
        echec('T2.9 Durée NULL', 'aucune erreur levée');
    EXCEPTION WHEN OTHERS THEN
        verifier_erreur('T2.9 Durée NULL', -20004, SQLCODE, SQLERRM);
    END;

    BEGIN
        pkg_prets.creer_demande(1, 50000, 120, 'MAISON', v_id_tmp);
        echec('T2.10 Type de projet inconnu', 'aucune erreur levée');
    EXCEPTION WHEN OTHERS THEN
        verifier_erreur('T2.10 Type de projet inconnu', -20005, SQLCODE, SQLERRM);
    END;

    BEGIN
        pkg_prets.creer_demande(1, 50000, 120, NULL, v_id_tmp);
        echec('T2.11 Type de projet NULL', 'aucune erreur levée');
    EXCEPTION WHEN OTHERS THEN
        verifier_erreur('T2.11 Type de projet NULL', -20005, SQLCODE, SQLERRM);
    END;

    -- =================================================================
    DBMS_OUTPUT.PUT_LINE('=== 3. changer_statut ===');
    -- =================================================================

    -- Acceptation de la demande créée en T2.1
    BEGIN
        pkg_prets.changer_statut(v_id, 'ACCEPTEE');
        SELECT statut, motif_refus INTO v_statut, v_motif
          FROM demandes_pret WHERE id = v_id;
        verifier_egal('T3.1a Acceptation : statut ACCEPTEE', 'ACCEPTEE', v_statut);
        verifier_egal('T3.1b Acceptation : aucun motif', NULL, v_motif);
    EXCEPTION WHEN OTHERS THEN echec('T3.1 Acceptation', SQLERRM);
    END;

    BEGIN
        pkg_prets.changer_statut(v_id, 'ACCEPTEE');
        echec('T3.2 Demande déjà traitée', 'aucune erreur levée');
    EXCEPTION WHEN OTHERS THEN
        verifier_erreur('T3.2 Demande déjà traitée', -20008, SQLCODE, SQLERRM);
    END;

    BEGIN
        pkg_prets.changer_statut(v_id, 'ANNULEE');
        echec('T3.3 Statut cible inconnu', 'aucune erreur levée');
    EXCEPTION WHEN OTHERS THEN
        verifier_erreur('T3.3 Statut cible inconnu', -20006, SQLCODE, SQLERRM);
    END;

    BEGIN
        pkg_prets.changer_statut(v_id, NULL);
        echec('T3.4 Statut cible NULL', 'aucune erreur levée');
    EXCEPTION WHEN OTHERS THEN
        verifier_erreur('T3.4 Statut cible NULL', -20006, SQLCODE, SQLERRM);
    END;

    -- Nouvelle demande en attente pour tester les refus
    BEGIN
        pkg_prets.creer_demande(2, 95000, 180, 'RENOVATION', v_id2);
    EXCEPTION WHEN OTHERS THEN echec('Préparation T3.5 à T3.7', SQLERRM);
    END;

    BEGIN
        pkg_prets.changer_statut(v_id2, 'REFUSEE');
        echec('T3.5 Refus sans motif', 'aucune erreur levée');
    EXCEPTION WHEN OTHERS THEN
        verifier_erreur('T3.5 Refus sans motif', -20007, SQLCODE, SQLERRM);
    END;

    BEGIN
        pkg_prets.changer_statut(v_id2, 'REFUSEE', '   ');
        echec('T3.6 Refus avec motif vide', 'aucune erreur levée');
    EXCEPTION WHEN OTHERS THEN
        verifier_erreur('T3.6 Refus avec motif vide', -20007, SQLCODE, SQLERRM);
    END;

    BEGIN
        pkg_prets.changer_statut(v_id2, 'REFUSEE', '  Dossier incomplet  ');
        SELECT statut, motif_refus INTO v_statut, v_motif
          FROM demandes_pret WHERE id = v_id2;
        verifier_egal('T3.7a Refus : statut REFUSEE', 'REFUSEE', v_statut);
        verifier_egal('T3.7b Refus : motif enregistré sans espaces', 'Dossier incomplet', v_motif);
    EXCEPTION WHEN OTHERS THEN echec('T3.7 Refus motivé', SQLERRM);
    END;

    BEGIN
        pkg_prets.changer_statut(999999, 'ACCEPTEE');
        echec('T3.8 Demande inexistante', 'aucune erreur levée');
    EXCEPTION WHEN OTHERS THEN
        verifier_erreur('T3.8 Demande inexistante', -20008, SQLCODE, SQLERRM);
    END;

    -- Un motif fourni lors d'une acceptation ne doit pas être enregistré
    BEGIN
        pkg_prets.creer_demande(2, 60000, 120, 'RENOVATION', v_id3);
        pkg_prets.changer_statut(v_id3, 'ACCEPTEE', 'Motif inutile');
        SELECT motif_refus INTO v_motif FROM demandes_pret WHERE id = v_id3;
        verifier_egal('T3.9 Acceptation : motif ignoré', NULL, v_motif);
    EXCEPTION WHEN OTHERS THEN echec('T3.9 Acceptation avec motif', SQLERRM);
    END;

    -- =================================================================
    DBMS_OUTPUT.PUT_LINE('=== 4. Trigger d''historique ===');
    -- =================================================================

    BEGIN
        SELECT COUNT(*) INTO v_nb
          FROM historique_statut
         WHERE demande_id = v_id
           AND ancien_statut = 'EN_ATTENTE'
           AND nouveau_statut = 'ACCEPTEE';
        verifier_egal('T4.1 Changement de statut historisé', '1', v_nb);

        -- Un UPDATE qui ne change pas le statut ne doit rien historiser
        UPDATE demandes_pret SET statut = statut WHERE id = v_id;
        SELECT COUNT(*) INTO v_nb FROM historique_statut WHERE demande_id = v_id;
        verifier_egal('T4.2 Pas d''historique si le statut ne change pas', '1', v_nb);
    EXCEPTION WHEN OTHERS THEN echec('T4 Trigger', SQLERRM);
    END;

    -- =================================================================
    DBMS_OUTPUT.PUT_LINE('=== 5. lister_demandes ===');
    -- =================================================================

    BEGIN
        SELECT COUNT(*) INTO v_attendu FROM demandes_pret WHERE statut = 'EN_ATTENTE';
        v_nb := compter_curseur('EN_ATTENTE', v_ordre_ok, v_filtre_ok);
        verifier_egal('T5.1 Nombre de demandes en attente', v_attendu, v_nb);
        verifier_egal('T5.2 Uniquement le statut demandé', 'OUI',
                      CASE WHEN v_filtre_ok THEN 'OUI' ELSE 'NON' END);

        SELECT COUNT(*) INTO v_attendu FROM demandes_pret;
        v_nb := compter_curseur(NULL, v_ordre_ok, v_filtre_ok);
        verifier_egal('T5.3 Toutes les demandes sans filtre', v_attendu, v_nb);
        verifier_egal('T5.4 Tri du plus récent au plus ancien', 'OUI',
                      CASE WHEN v_ordre_ok THEN 'OUI' ELSE 'NON' END);
    EXCEPTION WHEN OTHERS THEN echec('T5 lister_demandes', SQLERRM);
    END;

    -- =================================================================
    DBMS_OUTPUT.PUT_LINE('------------------------------------------');
    DBMS_OUTPUT.PUT_LINE('Résultat : ' || v_ok || ' OK, ' || v_ko || ' échec(s)');
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('ROLLBACK effectué : données intactes');

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Erreur inattendue, tests interrompus : ' || SQLERRM);
        RAISE;
END;
/