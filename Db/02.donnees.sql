INSERT INTO demandeurs (nom, prenom, email, nb_enfants, revenu_annuel, commune)
VALUES  ('Dubois', 'Sophie', 'sophie.dubois@mail.be', 3, 42000, 'Charleroi'),
        ('Lambert', 'Marc', 'marc.lambert@mail.be', 4, 51000, 'Mons'),
        ('Peeters', 'Anne', 'anne.peeters@mail.be', 1, 38000, 'Namur'),
        ('Maes', 'Julien', 'julien.maes@mail.be', 5, 36500, 'Charleroi'),
        ('Leroy', 'Fatima', 'fatima.leroy@mail.be', 3, 47800, 'Liège'),
        ('Jacobs', 'Thomas', 'thomas.jacobs@mail.be', 0, 55000, 'Quaregnon');

INSERT INTO demandes_pret (demandeur_id, montant, duree_mois, type_projet, statut, date_demande)
VALUES  (1, 185000, 300, 'ACHAT', 'ACCEPTEE', SYSDATE - 120),
        (1, 25000, 120, 'RENOVATION', 'EN_ATTENTE', SYSDATE - 10),
        (2, 240000, 360, 'CONSTRUCTION', 'EN_ATTENTE', SYSDATE - 25),
        (4, 40000, 180, 'RENOVATION', 'EN_ATTENTE', SYSDATE - 3),
        (5, 165000, 240, 'ACHAT', 'ACCEPTEE', SYSDATE - 200),
        (5, 18000, 60, 'RENOVATION', 'EN_ATTENTE', SYSDATE - 1);

INSERT INTO demandes_pret (demandeur_id, montant, duree_mois, type_projet, statut, motif_refus, date_demande)
VALUES  (4, 290000, 300, 'ACHAT', 'REFUSEE', 'Capacité de remboursement insuffisante', SYSDATE - 60);

COMMIT; -- INDISPENSABLE : sans COMMIT, les autres sessions (et mon API) ne voient rien