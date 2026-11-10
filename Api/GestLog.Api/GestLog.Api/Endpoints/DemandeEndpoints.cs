using GestLog.Api.Data;
using GestLog.Api.Models;

namespace GestLog.Api.Endpoints
{
    public static class DemandeEndpoints
    {
        public static RouteGroupBuilder MapDemandes(this IEndpointRouteBuilder app)
        {
            var groupe = app.MapGroup("/api/demandes").WithTags("Demandes");

            groupe.MapPut("/{id:int}/statut", async (int id, ChangementStatut changement, IDemandeRepository repo, CancellationToken ct) =>
            {
                await repo.ChangerStatutAsync(id, changement.Statut, changement.Motif, ct);
                return Results.NoContent();
            });

            groupe.MapPost("", async (NouvelleDemande demande, IDemandeRepository repo, CancellationToken ct) =>
            {
                int id = await repo.CreerAsync(demande, ct);
                return Results.Created($"/api/demandes/{id}", new { id });
            });

            groupe.MapGet("", async (string? statut, IDemandeRepository repo, CancellationToken ct) => Results.Ok(await repo.ListerAsync(statut, ct)));

            return groupe;
        }
    }
}
