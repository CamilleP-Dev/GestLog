import type { Demande, Statut } from "../types/demande";
import { LIBELLES_PROJET, LIBELLES_STATUT } from "../types/libelle";

interface ListeDemandesProps {
    demandes: Demande[],
    onChangerStatut: (id: number, statut: Statut) => void
}

const euros = new Intl.NumberFormat('fr-BE', {style: 'currency', currency: 'EUR'});

export default function ListeDemandes({demandes, onChangerStatut}: ListeDemandesProps) {
    if(demandes.length === 0)
    {
        return(<p className="vide">Aucune demande pour ce filtre.</p>)
    }

    return (
        <div className="tableau">
            <table>
                <thead>
                    <tr>
                        <th>#</th>
                        <th>Demandeur</th>
                        <th>Projet</th>
                        <th className="nombre">Montant</th>
                        <th>Durée</th>
                        <th>Date</th>
                        <th>Statut</th>
                        <th>Actions</th>
                    </tr>
                </thead>
                <tbody>
                    {demandes.map(d => (
                        <tr key={d.id}>
                            <td>{d.id}</td>
                            <td>{d.demandeur}</td>
                            <td>{LIBELLES_PROJET[d.typeProjet]}</td>
                            <td className="nombre">{euros.format(d.montant)}</td>
                            <td>{d.dureeMois} mois</td>
                            <td>{new Date(d.dateDemande).toLocaleDateString('fr-BE')}</td>
                            <td>
                                <span className={`badge ${(d.statut).toLowerCase()}`}>{LIBELLES_STATUT[d.statut]}</span>
                                {d.motifRefus && <div className="motif">{d.motifRefus}</div>}
                            </td>
                            <td>
                                {d.statut === 'EN_ATTENTE' &&
                                    <>
                                        <button onClick={() => onChangerStatut(d.id, "ACCEPTEE")}>Accepter</button>
                                        <button className="secondaire" onClick={() => onChangerStatut(d.id, "REFUSEE")}>Refuser</button>
                                    </>
                                }
                            </td>
                        </tr>
                    ))}
                </tbody>
            </table>
        </div>
    )
}