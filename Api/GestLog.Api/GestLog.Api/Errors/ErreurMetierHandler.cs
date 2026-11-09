using Microsoft.AspNetCore.Diagnostics;
using Microsoft.AspNetCore.Mvc;

namespace GestLog.Api.Errors
{
    public sealed class ErreurMetierHandler(IProblemDetailsService problemDetails) : IExceptionHandler
    {
        public async ValueTask<bool> TryHandleAsync(HttpContext context, Exception exception, CancellationToken ct)
        {
            if (exception is not ErreurMetierException erreur)
                return false;

            context.Response.StatusCode = StatusCodes.Status400BadRequest;

            return await problemDetails.TryWriteAsync(new ProblemDetailsContext
            {
                HttpContext = context,
                Exception = exception,
                ProblemDetails = new ProblemDetails
                {
                    Status = StatusCodes.Status400BadRequest,
                    Title = "Règle métier non respectée",
                    Detail = erreur.Message,
                    Extensions = { ["code"] = erreur.Code }
                }
            });
        }
    }
}
