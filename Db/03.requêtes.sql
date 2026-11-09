SELECT 
    COUNT(id) AS "nombre de demandes", 
    SUM(montant) AS "montant total", 
    ROUND(AVG(montant)) AS "montant moyen arrondi à l'euro",
    type_projet
FROM demandes_pret
GROUP BY type_projet;

SELECT 
    dp.montant,
    CONCAT(UPPER(d.nom), ' ', d.prenom) AS "nom complet" --ok pour 20c+ sinon UPPER(d.nom) || ' ' || d.prenom AS "nom complet"
FROM demandes_pret dp
JOIN demandeurs d
ON d.id = dp.demandeur_id
ORDER BY dp.montant DESC
FETCH FIRST 3 ROWS ONLY; --FETCH FIRST 3 ROWS WITH TIES pour montrer les ex-aequo


SELECT CONCAT(UPPER(nom), ' ', prenom) AS "nom complet"
FROM demandeurs
WHERE id NOT IN (   SELECT demandeur_id
                    FROM demandes_pret
                ); --attention utiliser NOT IN/IN peut casser si renvoi d'une valeur NULL car la colonne accepte les valeurs NULL

SELECT CONCAT(UPPER(nom), ' ', prenom) AS "nom complet"
FROM demandeurs d
WHERE NOT EXISTS (  SELECT 1
                    FROM demandes_pret dp
                    WHERE dp.demandeur_id = d.id
                ); 
-- préférer NOT EXISTS à NOT NULL pour éviter le piège d'une comparaison à une valeur NULL
-- EXISTS/NOT EXISTS vérifie l'existence d'une ligne selon la correspondanc, son avantage par rapport à une jointure est qu'il ne créé par de doublons

SELECT 
    id,
    TO_CHAR(date_demande, 'DD/MM/YYYY') AS "Date demande",
    TRUNC(SYSDATE - date_demande) AS "Ancienneté demande"
FROM demandes_pret;

SELECT 
    id,
    ROUND(montant/duree_mois, 2) AS "mensualité",
    NVL(motif_refus, '-') AS "motif refus"
FROM demandes_pret;

SELECT 
    CONCAT(UPPER(d.nom), ' ', d.prenom) AS "nom complet",
    LISTAGG(dp.type_projet, ', ') WITHIN GROUP (ORDER BY dp.type_projet) AS "projets"
FROM demandeurs d
JOIN demandes_pret dp
ON d.id = dp.demandeur_id
GROUP BY d.nom, d.prenom;

SELECT 
    montant,
    type_projet,
    RANK() OVER(PARTITION BY type_projet ORDER BY montant DESC) AS "rang"
FROM demandes_pret;

SELECT 
    id,
    type_projet,
    statut,
    TRUNC(SYSDATE - date_demande) AS "Ancienneté demande",
    date_demande
FROM demandes_pret
WHERE statut = 'EN_ATTENTE'
    AND date_demande < SYSDATE - 7
ORDER BY date_demande ASC;


