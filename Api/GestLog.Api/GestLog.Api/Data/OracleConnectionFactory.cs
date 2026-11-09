using Oracle.ManagedDataAccess.Client;
using System.Data.Common;

namespace GestLog.Api.Data
{
    public sealed class OracleConnectionFactory
    {
        private readonly string _connString;

        public OracleConnectionFactory(IConfiguration configuration)
        {
            var chaineDeBase = configuration.GetConnectionString("Oracle")
            ?? throw new InvalidOperationException("Chaîne de connexion 'Oracle' manquante dans appsettings.");

            var builder = new OracleConnectionStringBuilder(chaineDeBase);

            var motDePasse = configuration["Oracle:Pwd"];
            if (!string.IsNullOrEmpty(motDePasse))
            {
                builder.Password = motDePasse;
            }

            if (string.IsNullOrEmpty(builder.Password))
            {
                throw new InvalidOperationException("Mot de passe Oracle manquant.");
            }

            _connString = builder.ConnectionString;
        }


        public async Task<OracleConnection> OuvrirAsync(CancellationToken ct = default)
        {
            var conn = new OracleConnection(_connString);
            try
            {
                await conn.OpenAsync(ct);
                return conn;
            }
            catch
            {
                await conn.DisposeAsync();   // pas de fuite si l'ouverture échoue
                throw;
            }
        }
    }
}
