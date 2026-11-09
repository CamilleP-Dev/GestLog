using GestLog.Api.Models;
using Oracle.ManagedDataAccess.Client;

namespace GestLog.Api.Data
{
    public sealed class DemandeurRepository(OracleConnectionFactory factory) : IDemandeurRepository
    {
        public async Task<IReadOnlyList<DemandeurDto>> ListerAsync(CancellationToken ct = default)
        {
            await using OracleConnection conn = await factory.OuvrirAsync(ct);
            await using OracleCommand cmd = new OracleCommand("""
                SELECT id, nom, prenom, nb_enfants, pkg_prets.est_eligible(id) AS eligible
                FROM demandeurs
                ORDER BY nom
                """, conn);
            await using OracleDataReader r = await cmd.ExecuteReaderAsync(ct);

            List<DemandeurDto> liste = new List<DemandeurDto>();
            while(await r.ReadAsync())
            {
                liste.Add(new DemandeurDto(
                    Id: Convert.ToInt32(r["ID"]),
                    Nom: (string)r["NOM"],
                    Prenom: (string)r["PRENOM"],
                    NbEnfants: Convert.ToInt32(r["NB_ENFANTS"]),
                    Eligible: Convert.ToInt32(r["ELIGIBLE"]) == 1
                ));
            }

            return liste;
        }
    }
}
