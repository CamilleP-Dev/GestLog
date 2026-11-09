CREATE TABLE demandeurs (
    id              NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nom             VARCHAR2(50) NOT NULL,
    prenom          VARCHAR2(50) NOT NULL,
    email           VARCHAR2(100) NOT NULL,
    nb_enfants      NUMBER(2) DEFAULT 0 NOT NULL,
    revenu_annuel   NUMBER(10,2),
    commune         VARCHAR2(60),
    date_creation   DATE DEFAULT SYSDATE NOT NULL,
    CONSTRAINT uq_demandeurs_email UNIQUE (email),
    CONSTRAINT ck_demandeurs_enfants CHECK (nb_enfants >= 0)
);

CREATE TABLE demandes_pret (
    id              NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    demandeur_id    NUMBER NOT NULL,
    montant         NUMBER(10,2) NOT NULL,
    duree_mois      NUMBER(3) NOT NULL,
    type_projet     VARCHAR2(20) NOT NULL,
    statut          VARCHAR2(15) NOT NULL DEFAULT 'EN_ATTENTE',
    motif_refus     VARCHAR2(400),
    date_demande    DATE DEFAULT SYSDATE NOT NULL,
    CONSTRAINT fk_demande_demandeur FOREIGN KEY (demandeur_id) REFERENCES demandeurs(id),
    CONSTRAINT ck_demande_type CHECK (type_projet IN ('ACHAT', 'CONSTRUCTION', 'RENOVATION')),
    CONSTRAINT ck_demande_statut CHECK (statut IN ('EN_ATTENTE', 'ACCEPTEE', 'REFUSEE')),
    CONSTRAINT ck_demande_montant CHECK (montant > 0),
    CONSTRAINT ck_demande_duree CHECK (duree_mois BETWEEN 12 AND 360)
);

CREATE TABLE historique_statut (
    id                  NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    demande_id          NUMBER NOT NULL,
    ancien_statut       VARCHAR2(15),
    nouveau_statut      VARCHAR2(15) NOT NULL,
    modifie_par         VARCHAR2(128) DEFAULT USER NOT NULL,
    date_changement     TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
    CONSTRAINT fk_histo_demande FOREIGN KEY (demande_id) REFERENCES demandes_pret (id)
);

CREATE INDEX ix_demandes_demandeur  ON demandes_pret (demandeur_id);
CREATE INDEX ix_histo_demande       ON historique_statut (demande_id);
CREATE INDEX ix_demandes_statut     ON demandes_pret (statut);

-- DROP TABLE historique_statut;
-- DROP TABLE demandes_prets;
-- DROP TABLE demandeurs;