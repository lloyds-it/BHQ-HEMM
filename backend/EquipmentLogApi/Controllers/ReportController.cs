using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using EquipmentLogApi.DTOs.Report;
using EquipmentLogApi.Infrastructure.Repositories;
using EquipmentLogApi.Services.Interfaces;

namespace EquipmentLogApi.Controllers;

[Authorize]
[ApiController]
[Route("api/[controller]")]
public class ReportController : ControllerBase
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly IReportService _reportService;

    public ReportController(IUnitOfWork unitOfWork, IReportService reportService)
    {
        _unitOfWork = unitOfWork;
        _reportService = reportService;
    }

    [HttpGet("live-entries")]
    public async Task<IActionResult> GetLiveEntriesReport([FromQuery] ReportFilterDto filter)
    {
        var entries = await _unitOfWork.LiveEntries.GetAllAsync();

        // Populate navigation properties
        var projects = (await _unitOfWork.Projects.GetAllAsync()).ToDictionary(p => p.ProjectId);
        var equipment = (await _unitOfWork.Equipment.GetAllAsync()).ToDictionary(e => e.EquipmentId);
        var operators = (await _unitOfWork.Operators.GetAllAsync()).ToDictionary(o => o.OperatorId);

        foreach (var entry in entries)
        {
            if (projects.TryGetValue(entry.ProjectId, out var proj)) entry.Project = proj;
            if (equipment.TryGetValue(entry.EquipmentId, out var eq)) entry.Equipment = eq;
            if (operators.TryGetValue(entry.OperatorId, out var op)) entry.Operator = op;
        }

        // Apply Filters
        if (filter.StartDate.HasValue)
            entries = entries.Where(e => e.EntryTimestamp.Date >= filter.StartDate.Value.Date);

        if (filter.EndDate.HasValue)
            entries = entries.Where(e => e.EntryTimestamp.Date <= filter.EndDate.Value.Date);

        if (filter.ProjectId.HasValue)
            entries = entries.Where(e => e.ProjectId == filter.ProjectId.Value);

        if (filter.EquipmentId.HasValue)
            entries = entries.Where(e => e.EquipmentId == filter.EquipmentId.Value);

        if (filter.OperatorId.HasValue)
            entries = entries.Where(e => e.OperatorId == filter.OperatorId.Value);

        if (!string.IsNullOrEmpty(filter.ActivityType))
            entries = entries.Where(e => e.ActivityType.Equals(filter.ActivityType, StringComparison.OrdinalIgnoreCase));

        var sortedEntries = entries.OrderBy(e => e.EntryTimestamp).ToList();

        if (filter.Format.Equals("json", StringComparison.OrdinalIgnoreCase))
        {
            return Ok(sortedEntries.Select(e => new {
                e.EntryId,
                Project = e.Project?.ProjectName ?? "N/A",
                Equipment = e.Equipment?.EquipmentNumber ?? "N/A",
                Operator = e.Operator?.OperatorName ?? "N/A",
                Timestamp = e.EntryTimestamp,
                HmrValue = e.HMRValue,
                ActivityType = e.ActivityType
            }));
        }
        else if (filter.Format.Equals("pdf", StringComparison.OrdinalIgnoreCase))
        {
            var pdfBytes = _reportService.GenerateLiveEntryPdf(sortedEntries);
            return File(pdfBytes, "application/pdf", $"LiveEntries_{DateTime.Now:yyyyMMdd}.pdf");
        }
        else
        {
            var excelBytes = _reportService.GenerateLiveEntryExcel(sortedEntries);
            return File(excelBytes, "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", $"LiveEntries_{DateTime.Now:yyyyMMdd}.xlsx");
        }
    }

    [HttpGet("summary-logs")]
    public async Task<IActionResult> GetSummaryLogsReport([FromQuery] ReportFilterDto filter)
    {
        var logs = await _unitOfWork.SummaryLogs.GetAllAsync();

        // Populate navigation properties
        var projects = (await _unitOfWork.Projects.GetAllAsync()).ToDictionary(p => p.ProjectId);
        var equipment = (await _unitOfWork.Equipment.GetAllAsync()).ToDictionary(e => e.EquipmentId);
        var operators = (await _unitOfWork.Operators.GetAllAsync()).ToDictionary(o => o.OperatorId);

        foreach (var log in logs)
        {
            if (projects.TryGetValue(log.ProjectId, out var proj)) log.Project = proj;
            if (equipment.TryGetValue(log.EquipmentId, out var eq)) log.Equipment = eq;
            if (operators.TryGetValue(log.OperatorId, out var op)) log.Operator = op;
        }

        // Apply Filters
        if (filter.StartDate.HasValue)
            logs = logs.Where(l => l.Date.Date >= filter.StartDate.Value.Date);

        if (filter.EndDate.HasValue)
            logs = logs.Where(l => l.Date.Date <= filter.EndDate.Value.Date);

        if (filter.ProjectId.HasValue)
            logs = logs.Where(l => l.ProjectId == filter.ProjectId.Value);

        if (filter.EquipmentId.HasValue)
            logs = logs.Where(l => l.EquipmentId == filter.EquipmentId.Value);

        if (filter.OperatorId.HasValue)
            logs = logs.Where(l => l.OperatorId == filter.OperatorId.Value);

        if (!string.IsNullOrEmpty(filter.ActivityType))
            logs = logs.Where(l => l.ActivityType.Equals(filter.ActivityType, StringComparison.OrdinalIgnoreCase));

        if (!string.IsNullOrEmpty(filter.Shift))
            logs = logs.Where(l => l.Shift.Equals(filter.Shift, StringComparison.OrdinalIgnoreCase));

        var sortedLogs = logs.OrderBy(l => l.Date).ThenBy(l => l.StartTimestamp).ToList();

        if (filter.Format.Equals("json", StringComparison.OrdinalIgnoreCase))
        {
            return Ok(sortedLogs.Select(l => new {
                l.SummaryId,
                Project = l.Project?.ProjectName ?? "N/A",
                Date = l.Date,
                l.Shift,
                Equipment = l.Equipment?.EquipmentNumber ?? "N/A",
                Operator = l.Operator?.OperatorName ?? "N/A",
                l.StartHmr,
                l.EndHmr,
                l.TotalHmr,
                l.ClockHours,
                l.ActivityType,
                l.Diesel,
                l.WorkDone,
                l.Location
            }));
        }
        else if (filter.Format.Equals("pdf", StringComparison.OrdinalIgnoreCase))
        {
            var pdfBytes = _reportService.GenerateSummaryLogPdf(sortedLogs);
            return File(pdfBytes, "application/pdf", $"SummaryLogs_{DateTime.Now:yyyyMMdd}.pdf");
        }
        else
        {
            var excelBytes = _reportService.GenerateSummaryLogExcel(sortedLogs);
            return File(excelBytes, "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", $"SummaryLogs_{DateTime.Now:yyyyMMdd}.xlsx");
        }
    }

    [HttpGet("equipment")]
    public async Task<IActionResult> GetEquipmentReport([FromQuery] string? format, [FromQuery] int? projectId)
    {
        var equipment = await _unitOfWork.Equipment.GetAllAsync();
        var projects = (await _unitOfWork.Projects.GetAllAsync()).ToDictionary(p => p.ProjectId);

        foreach (var eq in equipment)
        {
            if (projects.TryGetValue(eq.ProjectId, out var proj)) eq.Project = proj;
        }

        if (projectId.HasValue)
        {
            equipment = equipment.Where(eq => eq.ProjectId == projectId.Value);
        }

        var list = equipment.OrderBy(eq => eq.EquipmentNumber).ToList();

        if (format != null && format.Equals("json", StringComparison.OrdinalIgnoreCase))
        {
            return Ok(list.Select(eq => new {
                eq.EquipmentId,
                eq.EquipmentNumber,
                Project = eq.Project?.ProjectName ?? "N/A",
                Status = eq.IsActive ? "Active" : "Inactive"
            }));
        }
        else if (format != null && format.Equals("pdf", StringComparison.OrdinalIgnoreCase))
        {
            var pdfBytes = _reportService.GenerateEquipmentPdf(list);
            return File(pdfBytes, "application/pdf", $"Equipment_{DateTime.Now:yyyyMMdd}.pdf");
        }
        else
        {
            var excelBytes = _reportService.GenerateEquipmentExcel(list);
            return File(excelBytes, "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", $"Equipment_{DateTime.Now:yyyyMMdd}.xlsx");
        }
    }

    [HttpGet("operators")]
    public async Task<IActionResult> GetOperatorsReport([FromQuery] string? format)
    {
        var operators = await _unitOfWork.Operators.GetAllAsync();
        var list = operators.OrderBy(op => op.OperatorName).ToList();

        if (format != null && format.Equals("json", StringComparison.OrdinalIgnoreCase))
        {
            return Ok(list.Select(op => new {
                op.OperatorId,
                op.OperatorName,
                op.Mobile,
                Status = op.IsActive ? "Active" : "Inactive"
            }));
        }
        else if (format != null && format.Equals("pdf", StringComparison.OrdinalIgnoreCase))
        {
            var pdfBytes = _reportService.GenerateOperatorPdf(list);
            return File(pdfBytes, "application/pdf", $"Operators_{DateTime.Now:yyyyMMdd}.pdf");
        }
        else
        {
            var excelBytes = _reportService.GenerateOperatorExcel(list);
            return File(excelBytes, "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", $"Operators_{DateTime.Now:yyyyMMdd}.xlsx");
        }
    }
}
