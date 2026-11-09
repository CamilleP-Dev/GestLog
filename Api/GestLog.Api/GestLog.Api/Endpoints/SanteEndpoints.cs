using GestLog.Api.Data;
using Oracle.ManagedDataAccess.Client;

namespace GestLog.Api.Endpoints
{
    public static class SanteEndpoints
    {
        public static IEndpointRouteBuilder MapSante(this IEndpointRouteBuilder app)
        {
            app.MapGet("/api/ping", async (OracleConnectionFactory factory, CancellationToken ct) =>
            {
                await using var conn = await factory.OuvrirAsync(ct);
                await using var cmd = new OracleCommand("SELECT USER, SYSDATE FROM DUAL", conn);
                await using var r = await cmd.ExecuteReaderAsync(ct);
                await r.ReadAsync(ct);

                return Results.Ok(new { utilisateur = r.GetString(0), dateServeur = r.GetDateTime(1) });
            })
            .WithTags("Santé");

            return app;
        }
    }
}
