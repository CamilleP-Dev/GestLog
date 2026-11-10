import type { Demandeur } from "../types/demandeur";
import { requete } from "./client";

export function getDemandeurs(signal?: AbortSignal): Promise<Demandeur[]>{
    return requete<Demandeur[]>('/demandeurs', {signal});
}