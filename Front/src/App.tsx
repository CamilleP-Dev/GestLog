import { useEffect, useState } from "react";
import FiltreStatut from "./components/FiltreStatut";
import type { Demande, Statut } from "./types/demande";
import { changerStatut, getDemandes } from "./api/demandes";
import ListeDemandes from "./components/ListeDemandes";
import FormulaireDemande from "./components/FormulaireDemande";

import "./App.css";

function App(){
  const [erreur, setErreur] = useState<string | null>(null);
  const [chargement, setChargement] = useState(true);
  const [version, setVersion] = useState(0);
  const [filtre, setFiltre] = useState<Statut | ''>('');
  const [demandes, setDemandes] = useState<Demande[]>([]);

  useEffect(() => {
    const controleur = new AbortController();
    getDemandes(filtre, controleur.signal)
      .then(data => {
        setDemandes(data);
        setErreur(null);
      })
      .catch((e: unknown) => {
          if(e instanceof Error && e.name !== 'AbortError')
            setErreur(e.message);
      })
      .finally(() => {
        if(!controleur.signal.aborted)
          setChargement(false);
      })
    return () => controleur.abort();
  }, [filtre, version])

  function recharger(){
    setVersion(v => v + 1);
  }

  function changeFiltre(nouveau: Statut | ''){
    setChargement(true);
    setFiltre(nouveau);
  }

  async function gererStatut(id: number, statut: Statut){
    let motif: string | undefined;

    if(statut === 'REFUSEE')
    {
      motif = window.prompt('Motif du refus ?')?.trim();

      if(!motif) return;
    }

    try {
      await changerStatut(id, statut, motif);
      recharger();
    }
    catch(e){
      setErreur(e instanceof Error ? e.message : 'Erreur inattendue.');
    }
  }

  return (
    <main className="app">
      <h1>GestLog</h1>
      <FormulaireDemande onCreee={recharger} />
      <section className="carte">
        <div className="barre">
          <h2>Demandes ({demandes.length})</h2>
          <FiltreStatut valeur={filtre} onChange={changeFiltre} />
        </div>
        {erreur && <p className="erreur">Erreur : {erreur}</p>}
        {chargement 
          ? <p>Chargement...</p>
          : <ListeDemandes demandes={demandes} onChangerStatut={gererStatut}/>
        }
      </section>
    </main>
  )
}

export default App