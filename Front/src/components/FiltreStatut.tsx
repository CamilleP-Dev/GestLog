import type { ChangeEvent } from "react";
import type { Statut } from "../types/demande";

interface FiltreStatutProps {
    valeur: Statut | '',
    onChange: (valeur: Statut | '') => void
};

const OPTIONS: {valeur: Statut | ''; libelle: string}[] = [
    {valeur: '', libelle: 'Tous les statuts'},
    {valeur: 'EN_ATTENTE', libelle: 'En attente'},
    {valeur: 'ACCEPTEE', libelle: 'Acceptées'},
    {valeur: 'REFUSEE', libelle: 'Refusées'}
]

export default function FiltreStatut({valeur, onChange}: FiltreStatutProps){
    function gererChangement(e: ChangeEvent<HTMLSelectElement>){
        onChange(e.target.value as Statut | '')
    }
    
    return(
        <div className="filtre">
            <label htmlFor="statut">Statut</label>
            <select id="statut" value={valeur} onChange={gererChangement}>
                {OPTIONS.map(o => (
                    <option value={o.valeur} key={o.valeur}>{o.libelle}</option>
                ))}
            </select>
        </div>
    )
}