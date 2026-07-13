using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using EquipmentLogApi.Domain.Constants;
using EquipmentLogApi.Domain.Entities;
using EquipmentLogApi.Infrastructure.Repositories;

namespace EquipmentLogApi.Controllers;

[Authorize]
[ApiController]
[Route("api/[controller]")]
public class LiveEntryController : ControllerBase
{
    private readonly IUnitOfWork _unitOfWork;

    public LiveEntryController(IUnitOfWork unitOfWork)
    {
        _unitOfWork = unitOfWork;
    }

    [HttpGet]
    public async Task<IActionResult> GetAll()
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

        // Return latest first
        return Ok(entries.OrderByDescending(e => e.EntryTimestamp));
    }

    [HttpGet("last-operator/{equipmentId}")]
    public async Task<IActionResult> GetLastOperatorForEquipment(int equipmentId)
    {
        var entries = await _unitOfWork.LiveEntries.FindAsync(e => e.EquipmentId == equipmentId);
        var lastEntry = entries.OrderByDescending(e => e.EntryTimestamp).FirstOrDefault();

        if (lastEntry == null)
            return Ok(null); // No previous entry, auto-fill nothing

        var op = await _unitOfWork.Operators.GetByIdAsync(lastEntry.OperatorId);
        return Ok(op);
    }

    [HttpGet("{id}")]
    public async Task<IActionResult> GetById(int id)
    {
        var entry = await _unitOfWork.LiveEntries.GetByIdAsync(id);
        if (entry == null)
            return NotFound();

        entry.Project = await _unitOfWork.Projects.GetByIdAsync(entry.ProjectId);
        entry.Equipment = await _unitOfWork.Equipment.GetByIdAsync(entry.EquipmentId);
        entry.Operator = await _unitOfWork.Operators.GetByIdAsync(entry.OperatorId);

        return Ok(entry);
    }

    [HttpPost]
    public async Task<IActionResult> Create([FromBody] LiveEntry entry)
    {
        if (!ModelState.IsValid)
            return BadRequest(ModelState);

        // Validation: HMRValue must be positive/numeric (already decimal, required)
        if (entry.HMRValue < 0)
            return BadRequest("HMR Value must be non-negative");

        // Automatically set timestamp to current if not provided
        if (entry.EntryTimestamp == default)
        {
            entry.EntryTimestamp = DateTime.UtcNow;
        }

        // Set who created it from the User claims
        entry.CreatedBy = User.Identity?.Name ?? "system";
        entry.CreatedDate = DateTime.UtcNow;

        try
        {
            await _unitOfWork.LiveEntries.AddAsync(entry);
            await _unitOfWork.CompleteAsync();
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { error = "Failed to save live entry to database.", detail = ex.InnerException?.Message ?? ex.Message });
        }

        return CreatedAtAction(nameof(GetById), new { id = entry.EntryId }, entry);
    }

    [Authorize(Roles = $"{Roles.Admin},{Roles.Supervisor}")]
    [HttpPut("{id}")]
    public async Task<IActionResult> Update(int id, [FromBody] LiveEntry entry)
    {
        if (id != entry.EntryId)
            return BadRequest("ID mismatch");

        if (!ModelState.IsValid)
            return BadRequest(ModelState);

        var existing = await _unitOfWork.LiveEntries.GetByIdAsync(id);
        if (existing == null)
            return NotFound();

        existing.ProjectId = entry.ProjectId;
        existing.EquipmentId = entry.EquipmentId;
        existing.OperatorId = entry.OperatorId;
        existing.EntryTimestamp = entry.EntryTimestamp;
        existing.HMRValue = entry.HMRValue;
        existing.ActivityType = entry.ActivityType;

        _unitOfWork.LiveEntries.Update(existing);
        await _unitOfWork.CompleteAsync();

        return NoContent();
    }

    [Authorize(Roles = Roles.Admin)]
    [HttpDelete("{id}")]
    public async Task<IActionResult> Delete(int id)
    {
        var existing = await _unitOfWork.LiveEntries.GetByIdAsync(id);
        if (existing == null)
            return NotFound();

        _unitOfWork.LiveEntries.Remove(existing);
        await _unitOfWork.CompleteAsync();

        return NoContent();
    }
}
