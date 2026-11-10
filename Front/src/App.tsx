import { useEffect, useState } from "react";

interface Ping{
  utilisateur: string,
  dateServeur: string
}

function App(){
  const [ping, setPing] = useState<Ping | null>(null);
  const [erreur, setErreur] = useState<string | null>(null);

  useEffect(() => {
    fetch('/api/ping')
      .then(res => {
        if(!res.ok) throw new Error(`HTTP ${res.status}`);
        return res.json();
      })
      .then(setPing)
      .catch(e => setErreur(e.message));
  }, [])

  return (
    <main>
      <h1>GestLog</h1>
      {erreur && <p>Erreur: {erreur}</p>}
      {ping ? <p>Connecté à Oracle en tant que {ping.utilisateur}</p> : !erreur && <p>Connexion à l'Api...</p>}
    </main>
  )
}

export default App