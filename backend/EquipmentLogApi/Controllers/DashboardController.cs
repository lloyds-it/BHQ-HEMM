using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using EquipmentLogApi.Domain.Constants;
using EquipmentLogApi.Infrastructure.Repositories;
using EquipmentLogApi.Domain.Entities;

namespace EquipmentLogApi.Controllers;

[Authorize]
[ApiController]
[Route("api/[controller]")]
public class DashboardController : ControllerBase
{
    private readonly IUnitOfWork _unitOfWork;

    public DashboardController(IUnitOfWork unitOfWork)
    {
        _unitOfWork = unitOfWork;
    }

    [HttpGet]
    public async Task<IActionResult> GetStats()
    {
        var today = DateTime.UtcNow.Date;

        // 1. Today's Live Entries
        var liveEntries = await _unitOfWork.LiveEntries.GetAllAsync();
        var todayEntries = liveEntries.Where(e => e.EntryTimestamp.Date == today).ToList();
        int todayLiveEntriesCount = todayEntries.Count;

        // 2. Equipment Status counts (Running, Idle, Breakdown, Stoppage)
        var allEquipment = await _unitOfWork.Equipment.GetAllAsync();
        var activeEquipment = allEquipment.Where(e => e.IsActive).ToList();

        int running = 0;
        int idle = 0;
        int breakdown = 0;
        int stoppage = 0;

        foreach (var eq in activeEquipment)
        {
            var eqEntries = liveEntries.Where(e => e.EquipmentId == eq.EquipmentId).ToList();
            var latestEntry = eqEntries.OrderByDescending(e => e.EntryTimestamp).FirstOrDefault();

            if (latestEntry != null)
            {
                switch (latestEntry.ActivityType)
                {
                    case ActivityTypes.Running:
                        running++;
                        break;
                    case ActivityTypes.Idle:
                        idle++;
                        break;
                    case ActivityTypes.Breakdown:
                        breakdown++;
                        break;
                    case ActivityTypes.Stoppage:
                        stoppage++;
                        break;
                }
            }
            else
            {
                // Default if no entries yet: assume Stoppage or Idle? Let's treat as Idle by default
                idle++;
            }
        }

        // 3. Recent Entries (Top 10 latest entries)
        var projects = (await _unitOfWork.Projects.GetAllAsync()).ToDictionary(p => p.ProjectId);
        var operators = (await _unitOfWork.Operators.GetAllAsync()).ToDictionary(o => o.OperatorId);
        
        var recentEntries = liveEntries
            .OrderByDescending(e => e.EntryTimestamp)
            .Take(10)
            .Select(e => new
            {
                e.EntryId,
                e.ProjectId,
                ProjectName = projects.TryGetValue(e.ProjectId, out var p) ? p.ProjectName : "N/A",
                e.EquipmentId,
                EquipmentNumber = allEquipment.FirstOrDefault(eq => eq.EquipmentId == e.EquipmentId)?.EquipmentNumber ?? "N/A",
                e.OperatorId,
                OperatorName = operators.TryGetValue(e.OperatorId, out var op) ? op.OperatorName : "N/A",
                e.EntryTimestamp,
                e.HMRValue,
                e.ActivityType,
                e.CreatedBy
            })
            .ToList();

        // KPI: Operator Performance (Entries per operator this month)
        var firstDayOfMonth = new DateTime(today.Year, today.Month, 1);
        var monthlyEntries = liveEntries.Where(e => e.EntryTimestamp >= firstDayOfMonth).ToList();
        var operatorStats = operators.Values.Select(op => new
        {
            OperatorName = op.OperatorName,
            TotalEntries = monthlyEntries.Count(e => e.OperatorId == op.OperatorId)
        }).OrderByDescending(x => x.TotalEntries).Take(5).ToList();

        // KPI: Shift Trends (Count per shift for last 7 days)
        var last7Days = today.AddDays(-7);
        var recentSummary = await _unitOfWork.SummaryLogs.GetAllAsync();
        var shiftStats = recentSummary.Where(s => s.Date >= last7Days)
            .GroupBy(s => s.Shift)
            .Select(g => new { Shift = g.Key, Count = g.Count() })
            .ToList();

        // KPI: Weekly trends (Entries per day for last 7 days)
        var weeklyTrends = new List<object>();
        for (int i = 6; i >= 0; i--)
        {
            var date = today.AddDays(-i);
            weeklyTrends.Add(new {
                Date = date.ToString("MMM dd"),
                Count = liveEntries.Count(e => e.EntryTimestamp.Date == date)
            });
        }

        return Ok(new
        {
            TodayLiveEntriesCount = todayLiveEntriesCount,
            RunningEquipmentCount = running,
            IdleEquipmentCount = idle,
            BreakdownEquipmentCount = breakdown,
            StoppageEquipmentCount = stoppage,
            RecentEntries = recentEntries,
            OperatorStats = operatorStats,
            ShiftStats = shiftStats,
            WeeklyTrends = weeklyTrends
        });
    }

    [HttpPost("seed")]
    [AllowAnonymous]
    public async Task<IActionResult> SeedDummyData()
    {
        var projects = (await _unitOfWork.Projects.GetAllAsync()).ToList();
        var equipments = (await _unitOfWork.Equipment.GetAllAsync()).ToList();
        var operators = (await _unitOfWork.Operators.GetAllAsync()).ToList();

        if (!projects.Any() || !equipments.Any() || !operators.Any())
            return BadRequest("Please ensure you have at least one Project, Equipment, and Operator in the master data before seeding.");

        var random = new Random();
        var activities = new[] { ActivityTypes.Running, ActivityTypes.Idle, ActivityTypes.Breakdown, ActivityTypes.Stoppage };
        var shifts = new[] { "Shift A", "Shift B", "Shift C" };

        var liveEntries = (await _unitOfWork.LiveEntries.GetAllAsync()).ToList();
        int nextLiveId = liveEntries.Any() ? liveEntries.Max(e => e.EntryId) + 1 : 1;

        var summaryLogs = (await _unitOfWork.SummaryLogs.GetAllAsync()).ToList();
        int nextSummaryId = summaryLogs.Any() ? summaryLogs.Max(s => s.SummaryId) + 1 : 1;

        for (int i = 0; i < 100; i++)
        {
            // Seed Live Entry
            var liveEntry = new LiveEntry
            {
                EntryId = nextLiveId++,
                ProjectId = projects[random.Next(projects.Count)].ProjectId,
                EquipmentId = equipments[random.Next(equipments.Count)].EquipmentId,
                OperatorId = operators[random.Next(operators.Count)].OperatorId,
                EntryTimestamp = DateTime.UtcNow.AddHours(-random.Next(1, 24 * 30)), // Past 30 days
                HMRValue = Math.Round((double)(random.Next(100, 5000) + random.NextDouble()), 2),
                ActivityType = activities[random.Next(activities.Length)],
                CreatedBy = "Seeder",
                CreatedDate = DateTime.UtcNow
            };
            await _unitOfWork.LiveEntries.AddAsync(liveEntry);

            // Seed Summary Log
            var summary = new SummaryLog
            {
                SummaryId = nextSummaryId++,
                ProjectId = projects[random.Next(projects.Count)].ProjectId,
                EquipmentId = equipments[random.Next(equipments.Count)].EquipmentId,
                Date = DateTime.UtcNow.AddDays(-random.Next(1, 30)),
                Shift = shifts[random.Next(shifts.Length)],
                OperatorId = operators[random.Next(operators.Count)].OperatorId,
                StartTimestamp = DateTime.UtcNow.AddDays(-random.Next(1, 30)),
                EndTimestamp = DateTime.UtcNow.AddDays(-random.Next(1, 30)).AddHours(8),
                StartHmr = Math.Round((double)random.Next(100, 2000), 2),
                EndHmr = Math.Round((double)random.Next(2001, 4000), 2),
                TotalHmr = Math.Round((double)random.Next(1, 12), 2),
                ClockHours = 8.0,
                ActivityType = activities[random.Next(activities.Length)],
                Remarks = "Seeded summary log",
                CreatedBy = "Seeder",
                CreatedDate = DateTime.UtcNow
            };
            await _unitOfWork.SummaryLogs.AddAsync(summary);
        }

        await _unitOfWork.CompleteAsync();

        return Ok(new { message = "Seeded 100 Live Entries and 100 Summary Logs successfully!" });
    }
}
