using Microsoft.EntityFrameworkCore;
using EquipmentLogApi.Domain.Entities;

namespace EquipmentLogApi.Infrastructure.Data;

public class ApplicationDbContext : DbContext
{
    public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options)
        : base(options)
    {
    }

    public DbSet<User> Users => Set<User>();
    public DbSet<Project> Projects => Set<Project>();
    public DbSet<Equipment> Equipment => Set<Equipment>();
    public DbSet<Operator> Operators => Set<Operator>();
    public DbSet<LiveEntry> LiveEntries => Set<LiveEntry>();
    public DbSet<SummaryLog> SummaryLogs => Set<SummaryLog>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);
        
        // Set the default schema as requested
        modelBuilder.HasDefaultSchema("BHQ_HEMM");

        // Microsoft Fabric does not support IDENTITY/AUTO_INCREMENT
        // We must manually generate IDs for all entities
        modelBuilder.Entity<User>().Property(e => e.UserId).ValueGeneratedNever();
        modelBuilder.Entity<Project>().Property(e => e.ProjectId).ValueGeneratedNever();
        modelBuilder.Entity<Equipment>().Property(e => e.EquipmentId).ValueGeneratedNever();
        modelBuilder.Entity<Operator>().Property(e => e.OperatorId).ValueGeneratedNever();
        modelBuilder.Entity<LiveEntry>().Property(e => e.EntryId).ValueGeneratedNever();
        modelBuilder.Entity<SummaryLog>().Property(e => e.SummaryId).ValueGeneratedNever();

    }

    public override int SaveChanges()
    {
        GenerateIds();
        return base.SaveChanges();
    }

    public override Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
    {
        GenerateIds();
        return base.SaveChangesAsync(cancellationToken);
    }

    private void GenerateIds()
    {
        var addedEntities = ChangeTracker.Entries().Where(e => e.State == EntityState.Added).ToList();
        
        foreach (var entry in addedEntities)
        {
            if (entry.Entity is User user && user.UserId == 0)
                user.UserId = Users.Any() ? Users.Max(e => e.UserId) + 1 : 1;
            else if (entry.Entity is Project project && project.ProjectId == 0)
                project.ProjectId = Projects.Any() ? Projects.Max(e => e.ProjectId) + 1 : 1;
            else if (entry.Entity is Equipment equipment && equipment.EquipmentId == 0)
                equipment.EquipmentId = Equipment.Any() ? Equipment.Max(e => e.EquipmentId) + 1 : 1;
            else if (entry.Entity is Operator op && op.OperatorId == 0)
                op.OperatorId = Operators.Any() ? Operators.Max(e => e.OperatorId) + 1 : 1;
            else if (entry.Entity is LiveEntry liveEntry)
            {
                if (liveEntry.EntryId == 0)
                    liveEntry.EntryId = LiveEntries.Any() ? LiveEntries.Max(e => e.EntryId) + 1 : 1;
                
                if (liveEntry.CreatedDate == default)
                    liveEntry.CreatedDate = DateTime.Now;
            }
            else if (entry.Entity is SummaryLog summaryLog && summaryLog.SummaryId == 0)
                summaryLog.SummaryId = SummaryLogs.Any() ? SummaryLogs.Max(e => e.SummaryId) + 1 : 1;
        }
    }
}
