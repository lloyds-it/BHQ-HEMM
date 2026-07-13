using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using EquipmentLogApi.Domain.Constants;
using EquipmentLogApi.Domain.Entities;
using EquipmentLogApi.Infrastructure.Repositories;

namespace EquipmentLogApi.Controllers;

[Authorize]
[ApiController]
[Route("api/[controller]")]
public class SummaryLogController : ControllerBase
{
    private readonly IUnitOfWork _unitOfWork;

    public SummaryLogController(IUnitOfWork unitOfWork)
    {
        _unitOfWork = unitOfWork;
    }

    [HttpGet]
    public async Task<IActionResult> GetAll()
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

        return Ok(logs.OrderByDescending(l => l.Date).ThenByDescending(l => l.StartTimestamp));
    }

    [HttpGet("{id}")]
    public async Task<IActionResult> GetById(int id)
    {
        var log = await _unitOfWork.SummaryLogs.GetByIdAsync(id);
        if (log == null)
            return NotFound();

        log.Project = await _unitOfWork.Projects.GetByIdAsync(log.ProjectId);
        log.Equipment = await _unitOfWork.Equipment.GetByIdAsync(log.EquipmentId);
        log.Operator = await _unitOfWork.Operators.GetByIdAsync(log.OperatorId);

        return Ok(log);
    }

    [HttpPost]
    public async Task<IActionResult> Create([FromBody] SummaryLog log)
    {
        if (!ModelState.IsValid)
            return BadRequest(ModelState);

        // Perform Automatic Calculations
        log.TotalHmr = log.EndHmr - log.StartHmr;
        
        var duration = log.EndTimestamp - log.StartTimestamp;
        log.ClockHours = duration.TotalHours;

        // Validations
        if (log.TotalHmr < 0)
            return BadRequest("End HMR must be greater than or equal to Start HMR");

        if (log.ClockHours < 0)
            return BadRequest("End Timestamp must be after Start Timestamp");

        log.CreatedBy = User.Identity?.Name ?? "system";
        log.CreatedDate = DateTime.UtcNow;

        try
        {
            await _unitOfWork.SummaryLogs.AddAsync(log);
            await _unitOfWork.CompleteAsync();
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { error = "Failed to save summary log to database.", detail = ex.InnerException?.Message ?? ex.Message });
        }

        return CreatedAtAction(nameof(GetById), new { id = log.SummaryId }, log);
    }

    [Authorize(Roles = $"{Roles.Admin},{Roles.Supervisor}")]
    [HttpPut("{id}")]
    public async Task<IActionResult> Update(int id, [FromBody] SummaryLog log)
    {
        if (id != log.SummaryId)
            return BadRequest("ID mismatch");

        if (!ModelState.IsValid)
            return BadRequest(ModelState);

        var existing = await _unitOfWork.SummaryLogs.GetByIdAsync(id);
        if (existing == null)
            return NotFound();

        // Re-calculate values
        existing.ProjectId = log.ProjectId;
        existing.Date = log.Date;
        existing.Shift = log.Shift;
        existing.EquipmentId = log.EquipmentId;
        existing.OperatorId = log.OperatorId;
        existing.StartTimestamp = log.StartTimestamp;
        existing.EndTimestamp = log.EndTimestamp;
        existing.StartHmr = log.StartHmr;
        existing.EndHmr = log.EndHmr;
        existing.ActivityType = log.ActivityType;
        existing.WorkDone = log.WorkDone;
        existing.Location = log.Location;
        existing.Remarks = log.Remarks;

        // Oils & Consumables
        existing.Diesel = log.Diesel;
        existing.HydraulicOil = log.HydraulicOil;
        existing.EngineOil = log.EngineOil;
        existing.TransmissionOil = log.TransmissionOil;
        existing.GearOil = log.GearOil;

        // Recalculations
        existing.TotalHmr = log.EndHmr - log.StartHmr;
        var duration = log.EndTimestamp - log.StartTimestamp;
        existing.ClockHours = duration.TotalHours;

        if (existing.TotalHmr < 0)
            return BadRequest("End HMR must be greater than or equal to Start HMR");

        if (existing.ClockHours < 0)
            return BadRequest("End Timestamp must be after Start Timestamp");

        _unitOfWork.SummaryLogs.Update(existing);
        await _unitOfWork.CompleteAsync();

        return NoContent();
    }

    [Authorize(Roles = Roles.Admin)]
    [HttpDelete("{id}")]
    public async Task<IActionResult> Delete(int id)
    {
        var existing = await _unitOfWork.SummaryLogs.GetByIdAsync(id);
        if (existing == null)
            return NotFound();

        _unitOfWork.SummaryLogs.Remove(existing);
        await _unitOfWork.CompleteAsync();

        return NoContent();
    }
}
