using GestLog.Api.Models;
using Oracle.ManagedDataAccess.Client;
using Oracle.ManagedDataAccess.Types;
using System.Data;

namespace GestLog.Api.Data
{
    public sealed class DemandeRepository(OracleConnectionFactory factory) : IDemandeRepository
    {
        public async Task ChangerStatutAsync(int id, string statut, string? motif, CancellationToken ct = default)
        {
            try
            {
                await using OracleConnection conn = await factory.OuvrirAsync(ct);
                await using OracleCommand cmd = Procedure(conn, "pkg_prets.changer_statut");

                cmd.Parameters.Add("p_demande_id", OracleDbType.Int32).Value = id;
                cmd.Parameters.Add("p_statut", OracleDbType.Varchar2).Value = (object?)statut ?? DBNull.Value;
                cmd.Parameters.Add("p_motif", OracleDbType.Varchar2).Value = (object?)motif ?? DBNull.Value;

                await cmd.ExecuteNonQueryAsync(ct);
            }
            catch (OracleException ex) when (OracleErreurs.EstMetier(ex))
            {
                throw OracleErreurs.VersMetier(ex);
            }
        }

        public async Task<int> CreerAsync(NouvelleDemande demande, CancellationToken ct = default)
        {
            try
            {
                await using OracleConnection conn = await factory.OuvrirAsync(ct);
                await using OracleCommand cmd = Procedure(conn, "pkg_prets.creer_demande");

                cmd.Parameters.Add("p_demandeur_id", OracleDbType.Int32).Value = demande.DemandeurId;
                cmd.Parameters.Add("p_montant", OracleDbType.Int32).Value = demande.Montant;
                cmd.Parameters.Add("p_duree_mois", OracleDbType.Int32).Value = demande.DureeMois;
                cmd.Parameters.Add("p_type_projet", OracleDbType.Varchar2).Value = (object?)demande.TypeProjet ?? DBNull.Value;
                
                var pId = cmd.Parameters.Add("p_id", OracleDbType.Int32);
                pId.Direction = ParameterDirection.Output;

                await cmd.ExecuteNonQueryAsync(ct);

                return ((OracleDecimal)pId.Value).ToInt32();
            }
            catch(OracleException ex) when (OracleErreurs.EstMetier(ex))
            {
                throw OracleErreurs.VersMetier(ex);
            }            
        }

        public async Task<IReadOnlyList<DemandeDto>> ListerAsync(string? statut, CancellationToken ct = default)
        {
            await using OracleConnection conn = await factory.OuvrirAsync(ct);
            await using OracleCommand cmd = Procedure(conn, "pkg_prets.lister_demandes");

            cmd.Parameters.Add("p_statut", OracleDbType.Varchar2).Value = (object?)statut ?? DBNull.Value;

            var pResult = cmd.Parameters.Add("p_result", OracleDbType.RefCursor);
            pResult.Direction = ParameterDirection.Output;

            await cmd.ExecuteNonQueryAsync(ct);

            using var refCursor = (OracleRefCursor)pResult.Value;
            await using var r = refCursor.GetDataReader();

            List<DemandeDto> liste = new List<DemandeDto>();
            while (await r.ReadAsync())
            {
                liste.Add(new DemandeDto(
                    Id: Convert.ToInt32(r["ID"]),
                    Demandeur: (string)r["DEMANDEUR"],
                    Montant: Convert.ToInt32(r["MONTANT"]),
                    DureeMois: Convert.ToInt32(r["DUREE_MOIS"]),
                    TypeProjet: (string)r["TYPE_PROJET"],
                    Statut: (string)r["STATUT"],
                    DateDemande: (DateTime)r["DATE_DEMANDE"],
                    MotifRefus: r["MOTIF_REFUS"] is DBNull ? null : (string)r["MOTIF_REFUS"]
                ));
            }

            return liste;
        }


        private static OracleCommand Procedure(OracleConnection conn, string nom) => new(nom, conn) { CommandType = CommandType.StoredProcedure, BindByName = true };
    }
}
