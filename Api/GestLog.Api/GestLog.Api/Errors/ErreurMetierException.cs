namespace GestLog.Api.Errors
{
    public sealed class ErreurMetierException(int code, string message, Exception? inner = null)
    : Exception(message, inner)
    {
        public int Code { get; } = code;
    }
}
