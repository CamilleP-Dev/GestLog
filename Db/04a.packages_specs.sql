CREATE OR REPLACE PACKAGE pkg_prets AS
    c_montant_max CONSTANT NUMBER := 300000;
    FUNCTION est_eligible (p_demandeur_id IN demandeurs.id%TYPE) RETURN NUMBER;
    PROCEDURE creer_demande (
        p_demandeur_id IN demandes_pret.demandeur_id%TYPE, 
        p_montant IN demandes_pret.montant%TYPE, 
        p_duree_mois IN demandes_pret.duree_mois%TYPE, 
        p_type_projet IN demandes_pret.type_projet%TYPE, 
        p_id OUT demandes_pret.id%TYPE
    );
    PROCEDURE changer_statut (
        p_demande_id IN demandes_pret.id%TYPE,
        p_statut IN demandes_pret.statut%TYPE,
        p_motif IN demandes_pret.motif_refus%TYPE DEFAULT NULL
    );
    PROCEDURE lister_demandes (
        p_statut IN demandes_pret.statut%TYPE DEFAULT NULL,
        p_result OUT SYS_REFCURSOR
    );
END pkg_prets;
/