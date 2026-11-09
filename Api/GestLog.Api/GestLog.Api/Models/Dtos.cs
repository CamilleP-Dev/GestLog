namespace GestLog.Api.Models
{
    public record DemandeurDto(int Id, string Nom, string Prenom, int NbEnfants, bool Eligible);

    public record DemandeDto(int Id, string Demandeur, decimal Montant, int DureeMois,
                             string TypeProjet, string Statut, DateTime DateDemande, string? MotifRefus);

    public record NouvelleDemande(int DemandeurId, decimal Montant, int DureeMois, string TypeProjet);

    public record ChangementStatut(string Statut, string? Motif);
}
