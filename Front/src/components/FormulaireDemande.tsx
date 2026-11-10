import { useEffect, useState, type FormEvent } from "react";
import type { TypeProjet } from "../types/demande";
import type { Demandeur } from "../types/demandeur";
import { getDemandeurs } from "../api/demandeurs";
import { creerDemande } from "../api/demandes";
import { LIBELLES_PROJET } from "../types/libelle";

interface FormulaireDemandeProps {
    onCreee: () => void
}

interface Message {
    texte: string,
    erreur: boolean
}

export default function FormulaireDemande({onCreee}: FormulaireDemandeProps) {
    const [demandeurs, setDemandeurs] = useState<Demandeur[]>([]);
    const [demandeurId, setDemandeurId] = useState('');
    const [montant, setMontant] = useState('');
    const [dureeMois, setDureeMois] = useState('240');
    const [typeProjet, setTypeProjet] = useState<TypeProjet>('ACHAT');
    const [message, setMessage] = useState<Message | null>(null);
    const [envoi, setEnvoi] = useState(false);

    useEffect(() =>  {
        const controleur = new AbortController();
        getDemandeurs(controleur.signal)
            .then(setDemandeurs)
            .catch((e: unknown) => {
                if(e instanceof Error && e.name !== 'AbortError')
                    setMessage({texte: e.message, erreur: true});
            })
        return () => controleur.abort();
    }, [])

    async function soumettre(e: FormEvent<HTMLFormElement>){
        e.preventDefault();
        setMessage(null);

        if(demandeurId === '')
        {
            setMessage({texte: 'Veuillez choisir un demandeur', erreur: true});
            return;
        }

        const montantNum = Number(montant);
        if(!(montantNum > 0))
        {
            setMessage({texte: 'Veuillez saisir un montant positif.', erreur: true});
            return;
        }
        
        setEnvoi(true);
        try{
            const id = await creerDemande({
                demandeurId: Number(demandeurId),
                montant: montantNum,
                dureeMois: Number(dureeMois),
                typeProjet
            })

            setMessage({texte: `Demande n°${id} enregistrée`, erreur: false});
            setMontant('');
            setDemandeurId('');
            setDureeMois('240');
            setTypeProjet('ACHAT');
            onCreee();
        }
        catch(e){
            setMessage({texte: e instanceof Error ? e.message : 'Erreur inattendue.', erreur: true});
        }
        finally{
            setEnvoi(false);
        }
    }

    return (
        <form className="carte" onSubmit={soumettre}>
            <h2>Nouvelle demande</h2>

            <div className="grille">

                <div className="champ">
                    <label htmlFor="demandeur">Demandeur</label>
                    <select id="demandeur" value={demandeurId} onChange={e => setDemandeurId(e.target.value)}>
                        <option value="">-- choisir --</option>
                        {demandeurs.map(d => (
                            <option key={d.id} value={d.id}>{`${d.nom} ${d.prenom} (${d.nbEnfants} enf.)${d.eligible ? "" : " - non éligible"}`}</option>
                        ))}
                    </select>
                </div>

                <div className="champ">
                    <label htmlFor="montant">Montant (EUR)</label>
                    <input id="montant" type="number" value={montant} onChange={e => setMontant(e.target.value)} min={1} />
                </div>

                <div className="champ">
                    <label htmlFor="duree">Durée (mois)</label>
                    <input id="duree" type="number" value={dureeMois} onChange={e => setDureeMois(e.target.value)} min={12} max={360} />
                </div>

                <div className="champ">
                    <label htmlFor="type">Type de projet</label>
                    <select id="type" value={typeProjet} onChange={e => setTypeProjet(e.target.value as TypeProjet)}>
                        {Object.entries(LIBELLES_PROJET).map(([valeur, libelle]) => (
                            <option key={valeur} value={valeur}>{libelle}</option>
                        ))}
                    </select>
                </div>
            
            </div>

            <button type="submit" disabled={envoi}>{envoi ? "Envoi..." : "Enregistrer"}</button>
            
            {message && <p className={`message ${message.erreur ? "erreur" : "succes"}`}>{message.texte}</p>}
        </form>
    )
}