using GestLog.Api.Models;

namespace GestLog.Api.Data
{
    public interface IDemandeRepository
    {
        Task<IReadOnlyList<DemandeDto>> ListerAsync(string? statut, CancellationToken ct = default);
        Task<int> CreerAsync(NouvelleDemande demande, CancellationToken ct = default);
        Task ChangerStatutAsync(int id, string statut, string? motif, CancellationToken ct = default);
    }
}
