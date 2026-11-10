import type { Demande, NouvelleDemande, Statut } from "../types/demande";
import { requete } from "./client";

export function getDemandes(statut: Statut | '', signal?: AbortSignal): Promise<Demande[]> {
    const chemin = statut ? `/demandes?${new URLSearchParams({statut})}` : '/demandes';
    return requete<Demande[]>(chemin, {signal});
}

export async function creerDemande(demande: NouvelleDemande): Promise<number> {
    const id = await requete<number>('/demandes', {method: 'POST', body: demande});
    return id;
}

export function changerStatut(id: number, statut: Statut, motif?: string): Promise<void>{
    return requete<void>(`/demandes/${id}/statut`, {method: 'PUT', body: {statut, motif: motif ?? null}});
}