using EquipmentLogApi.Domain.Entities;

namespace EquipmentLogApi.Infrastructure.Repositories;

public interface IUnitOfWork : IDisposable
{
    IRepository<User> Users { get; }
    IRepository<Project> Projects { get; }
    IRepository<Equipment> Equipment { get; }
    IRepository<Operator> Operators { get; }
    IRepository<LiveEntry> LiveEntries { get; }
    IRepository<SummaryLog> SummaryLogs { get; }
    Task<int> CompleteAsync();
}
