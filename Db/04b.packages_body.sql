CREATE OR REPLACE PACKAGE BODY pkg_prets AS
    FUNCTION est_eligible (p_demandeur_id IN demandeurs.id%TYPE) RETURN NUMBER IS
        v_nb_enfants demandeurs.nb_enfants%TYPE;
    BEGIN
        SELECT nb_enfants INTO v_nb_enfants
        FROM demandeurs
        WHERE id = p_demandeur_id;

        IF(v_nb_enfants >= 3) THEN
            RETURN 1;
        ELSE
            RETURN 0;
        END IF;
    EXCEPTION 
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20001, 'Demandeur ' || p_demandeur_id || ' introuvable');
    END est_eligible;

    PROCEDURE creer_demande (
        p_demandeur_id IN demandes_pret.demandeur_id%TYPE, 
        p_montant IN demandes_pret.montant%TYPE, 
        p_duree_mois IN demandes_pret.duree_mois%TYPE, 
        p_type_projet IN demandes_pret.type_projet%TYPE, 
        p_id OUT demandes_pret.id%TYPE
    ) IS
    BEGIN
        IF (p_montant IS NULL OR p_montant <= 0 OR p_montant > c_montant_max) THEN
            RAISE_APPLICATION_ERROR(-20002, 'Montant autorisé compris entre 1 et ' || c_montant_max);
        ELSIF (est_eligible(p_demandeur_id) = 0) THEN
            RAISE_APPLICATION_ERROR(-20003, 'Demandeur ' || p_demandeur_id || ' est inéligible');
        ELSIF (p_duree_mois IS NULL OR p_duree_mois < 12 OR p_duree_mois > 360) THEN
            RAISE_APPLICATION_ERROR(-20004, 'Durée en mois autorisé doit être comprise entre 12 et 360');
        ELSIF (p_type_projet IS NULL OR UPPER(p_type_projet) NOT IN ('ACHAT', 'CONSTRUCTION', 'RENOVATION')) THEN
            RAISE_APPLICATION_ERROR(-20005, 'Le type de projet peut seulement être ACHAT, CONSTRUCTION ou RENOVATION');
        END IF;

        INSERT INTO demandes_pret (demandeur_id, montant, duree_mois, type_projet)
        VALUES (p_demandeur_id, p_montant, p_duree_mois, UPPER(p_type_projet))
        RETURNING id INTO p_id;         
    END creer_demande;

    PROCEDURE changer_statut (
        p_demande_id IN demandes_pret.id%TYPE,
        p_statut IN demandes_pret.statut%TYPE,
        p_motif IN demandes_pret.motif_refus%TYPE DEFAULT NULL
    ) IS
        v_nb NUMBER;
    BEGIN
        IF(p_statut IS NULL OR p_statut NOT IN ('ACCEPTEE', 'REFUSEE')) then
            RAISE_APPLICATION_ERROR(-20006, 'Le nouveau statut peut seulement être ACCEPTEE ou REFUSEE');
        ELSIF (p_statut = 'REFUSEE' AND TRIM(p_motif) IS NULL) THEN    
            RAISE_APPLICATION_ERROR(-20007, 'Pour un refus, le motif de refus est obligatoire');
        END IF;

        UPDATE demandes_pret
        SET statut = p_statut,
            motif_refus = CASE WHEN p_statut = 'REFUSEE' THEN TRIM(p_motif) END
        WHERE id = p_demande_id AND statut = 'EN_ATTENTE';

        v_nb:= SQL%ROWCOUNT;

        IF(v_nb = 0) THEN
            RAISE_APPLICATION_ERROR(-20008, 'La demande est inexistante ou a déjà été traitée.');
        END IF;
    END changer_statut;

    PROCEDURE lister_demandes (
        p_statut IN demandes_pret.statut%TYPE DEFAULT NULL,
        p_result OUT SYS_REFCURSOR
    ) IS
    BEGIN
        OPEN p_result FOR
            SELECT 
                dp.id,
                d.nom || ' ' || d.prenom AS demandeur,
                dp.montant,
                dp.duree_mois,
                dp.type_projet,
                dp.statut,
                dp.date_demande,
                dp.motif_refus
            FROM demandeurs d
            JOIN demandes_pret dp
            ON d.id = dp.demandeur_id
            WHERE p_statut IS NULL OR dp.statut = p_statut
            ORDER BY dp.date_demande DESC;
    END lister_demandes;

END pkg_prets;
/