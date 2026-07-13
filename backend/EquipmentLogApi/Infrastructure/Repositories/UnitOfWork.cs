using EquipmentLogApi.Domain.Entities;
using EquipmentLogApi.Infrastructure.Data;

namespace EquipmentLogApi.Infrastructure.Repositories;

public class UnitOfWork : IUnitOfWork
{
    private readonly ApplicationDbContext _context;
    private IRepository<User>? _users;
    private IRepository<Project>? _projects;
    private IRepository<Equipment>? _equipment;
    private IRepository<Operator>? _operators;
    private IRepository<LiveEntry>? _liveEntries;
    private IRepository<SummaryLog>? _summaryLogs;

    public UnitOfWork(ApplicationDbContext context)
    {
        _context = context;
    }

    public IRepository<User> Users => _users ??= new Repository<User>(_context);
    public IRepository<Project> Projects => _projects ??= new Repository<Project>(_context);
    public IRepository<Equipment> Equipment => _equipment ??= new Repository<Equipment>(_context);
    public IRepository<Operator> Operators => _operators ??= new Repository<Operator>(_context);
    public IRepository<LiveEntry> LiveEntries => _liveEntries ??= new Repository<LiveEntry>(_context);
    public IRepository<SummaryLog> SummaryLogs => _summaryLogs ??= new Repository<SummaryLog>(_context);

    public async Task<int> CompleteAsync()
    {
        return await _context.SaveChangesAsync();
    }

    public void Dispose()
    {
        _context.Dispose();
        GC.SuppressFinalize(this);
    }
}
