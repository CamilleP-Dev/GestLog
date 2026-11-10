import type { ProblemDetails } from "../types/erreur";

const BASE_URL = '/api';

interface OptionsRequete {
    method?: 'GET' | 'POST' | 'PUT' | 'DELETE',
    body?: unknown,
    signal?: AbortSignal
}

export async function requete<T>(chemin: string , {method = 'GET', body, signal }: OptionsRequete = {}): Promise<T>{
    const avecCorps = body !== undefined;
    const res = await fetch(`${BASE_URL}${chemin}`,  {
        method,
        signal,
        headers: avecCorps ? {'Content-Type': 'application/json'}: undefined,
        body: avecCorps ? JSON.stringify(body) : undefined
    });

    if (!res.ok)
    {
        const corps = (await res.json().catch(() => null)) as ProblemDetails | null;
        throw new Error(corps?.detail ?? `Erreur HTTP ${res.status}`);
    }

    if (res.status === 204)
        return undefined as T;

    return (await res.json()) as T;
}