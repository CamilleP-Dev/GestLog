export type Statut = 'EN_ATTENTE' | 'ACCEPTEE' | 'REFUSEE';
export type TypeProject = 'ACHAT' | 'CONSTRUCTION' | 'RENOVATION';

export interface Demande {
    id: number,
    demandeur: string,
    montant: number,
    dureeMois: number,
    typeProject: TypeProject,
    statut: Statut,
    dateDemande: string,
    motifRefus: string | null
}

export interface NouvelleDemande {
    demandeurId: number,
    montant: number,
    dureeMois: number,
    typeProject: TypeProject
}