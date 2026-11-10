import type { Statut, TypeProjet } from "./demande"

export const LIBELLES_STATUT: Record<Statut, string> = {
    EN_ATTENTE: 'En attente',
    ACCEPTEE: 'Acceptée',
    REFUSEE: 'Refusée'
}

export const LIBELLES_PROJET: Record<TypeProjet, string> = {
    ACHAT: 'Achat',
    RENOVATION: 'Rénovation',
    CONSTRUCTION: 'Construction'
}