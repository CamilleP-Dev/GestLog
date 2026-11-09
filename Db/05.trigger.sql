CREATE OR REPLACE TRIGGER trg_demandes_historique
AFTER UPDATE OF statut ON demandes_pret
FOR EACH ROW
WHEN (NEW.statut <> OLD.statut)
BEGIN
    INSERT INTO historique_statut (demande_id, ancien_statut, nouveau_statut)
    VALUES (:OLD.id, :OLD.statut, :NEW.statut);
END;
/