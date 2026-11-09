using GestLog.Api.Data;

namespace GestLog.Api.Endpoints
{
    public static class DemandeursEndpoints
    {
        public static RouteGroupBuilder MapDemandeurs(this IEndpointRouteBuilder app)
        {
            var groupe = app.MapGroup("/api/demandeurs").WithTags("Demandeurs");

            groupe.MapGet("", async (IDemandeurRepository repo, CancellationToken ct) => Results.Ok(await repo.ListerAsync(ct)));

            return groupe;
        }
    }
}
