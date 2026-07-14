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

        // Primary keys and auto-increment (IDENTITY) columns are configured by default by EF Core.

        // Avoid multiple cascade paths in SQL Server
        modelBuilder.Entity<LiveEntry>()
            .HasOne(e => e.Project)
            .WithMany()
            .HasForeignKey(e => e.ProjectId)
            .OnDelete(DeleteBehavior.Restrict);

        modelBuilder.Entity<LiveEntry>()
            .HasOne(e => e.Equipment)
            .WithMany()
            .HasForeignKey(e => e.EquipmentId)
            .OnDelete(DeleteBehavior.Restrict);

        modelBuilder.Entity<LiveEntry>()
            .HasOne(e => e.Operator)
            .WithMany()
            .HasForeignKey(e => e.OperatorId)
            .OnDelete(DeleteBehavior.Restrict);

        modelBuilder.Entity<SummaryLog>()
            .HasOne(e => e.Project)
            .WithMany()
            .HasForeignKey(e => e.ProjectId)
            .OnDelete(DeleteBehavior.Restrict);

        modelBuilder.Entity<SummaryLog>()
            .HasOne(e => e.Equipment)
            .WithMany()
            .HasForeignKey(e => e.EquipmentId)
            .OnDelete(DeleteBehavior.Restrict);

        modelBuilder.Entity<SummaryLog>()
            .HasOne(e => e.Operator)
            .WithMany()
            .HasForeignKey(e => e.OperatorId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}
