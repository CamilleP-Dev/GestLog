export type Statut = 'EN_ATTENTE' | 'ACCEPTEE' | 'REFUSEE';
export type TypeProjet = 'ACHAT' | 'CONSTRUCTION' | 'RENOVATION';

export interface Demande {
    id: number,
    demandeur: string,
    montant: number,
    dureeMois: number,
    typeProjet: TypeProjet,
    statut: Statut,
    dateDemande: string,
    motifRefus: string | null
}

export interface NouvelleDemande {
    demandeurId: number,
    montant: number,
    dureeMois: number,
    typeProjet: TypeProjet
}