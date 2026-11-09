using GestLog.Api.Errors;
using Oracle.ManagedDataAccess.Client;

namespace GestLog.Api.Data
{
    internal class OracleErreurs
    {
        public static bool EstMetier(OracleException ex) => ex.Number is >= 20000 and <= 20999;

        public static ErreurMetierException VersMetier(OracleException ex)
        {
            var premiereLigne = ex.Message.Split('\n')[0];
            var i = premiereLigne.IndexOf(": ", StringComparison.Ordinal);
            var message = i >= 0 ? premiereLigne[(i + 2)..] : premiereLigne;
            return new ErreurMetierException(ex.Number, message, ex);
        }
    }
}
