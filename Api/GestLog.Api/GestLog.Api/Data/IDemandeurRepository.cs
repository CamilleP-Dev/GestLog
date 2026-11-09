using GestLog.Api.Models;

namespace GestLog.Api.Data
{
    public interface IDemandeurRepository
    {
        Task<IReadOnlyList<DemandeurDto>> ListerAsync(CancellationToken ct = default);
    }
}
