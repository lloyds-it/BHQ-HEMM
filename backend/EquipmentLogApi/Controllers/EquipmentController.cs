using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using EquipmentLogApi.Domain.Constants;
using EquipmentLogApi.Domain.Entities;
using EquipmentLogApi.Infrastructure.Repositories;
using Microsoft.EntityFrameworkCore;

namespace EquipmentLogApi.Controllers;

[Authorize]
[ApiController]
[Route("api/[controller]")]
public class EquipmentController : ControllerBase
{
    private readonly IUnitOfWork _unitOfWork;

    public EquipmentController(IUnitOfWork unitOfWork)
    {
        _unitOfWork = unitOfWork;
    }

    [HttpGet]
    public async Task<IActionResult> GetAll([FromQuery] string? search)
    {
        // To include project, we can fetch all and then filter
        var equipment = await _unitOfWork.Equipment.GetAllAsync();

        // Populate projects manually because generic repository doesn't include navigational properties
        var projects = await _unitOfWork.Projects.GetAllAsync();
        var projectsMap = projects.ToDictionary(p => p.ProjectId);

        foreach (var eq in equipment)
        {
            if (projectsMap.TryGetValue(eq.ProjectId, out var project))
            {
                eq.Project = project;
            }
        }

        if (!string.IsNullOrEmpty(search))
        {
            search = search.Trim();
            // Filter by full equipment number or last 4 digits
            equipment = equipment.Where(eq => 
                eq.EquipmentNumber.Contains(search, StringComparison.OrdinalIgnoreCase) || 
                (search.Length >= 4 && eq.EquipmentNumber.EndsWith(search)) ||
                (eq.EquipmentNumber.Length >= 4 && eq.EquipmentNumber.Substring(eq.EquipmentNumber.Length - 4).Contains(search))
            );
        }

        return Ok(equipment);
    }

    [HttpGet("{id}")]
    public async Task<IActionResult> GetById(int id)
    {
        var eq = await _unitOfWork.Equipment.GetByIdAsync(id);
        if (eq == null)
            return NotFound();

        eq.Project = await _unitOfWork.Projects.GetByIdAsync(eq.ProjectId);
        return Ok(eq);
    }

    [Authorize(Roles = Roles.Admin)]
    [HttpPost]
    public async Task<IActionResult> Create([FromBody] Equipment equipment)
    {
        if (!ModelState.IsValid)
            return BadRequest(ModelState);

        try
        {
            await _unitOfWork.Equipment.AddAsync(equipment);
            await _unitOfWork.CompleteAsync();
            return CreatedAtAction(nameof(GetById), new { id = equipment.EquipmentId }, equipment);
        }
        catch (DbUpdateException ex)
        {
            return BadRequest(new { error = "Database error while creating equipment.", detail = ex.InnerException?.Message ?? ex.Message });
        }
    }

    [Authorize(Roles = Roles.Admin)]
    [HttpPut("{id}")]
    public async Task<IActionResult> Update(int id, [FromBody] Equipment equipment)
    {
        if (id != equipment.EquipmentId)
            return BadRequest("ID mismatch");

        if (!ModelState.IsValid)
            return BadRequest(ModelState);

        var existing = await _unitOfWork.Equipment.GetByIdAsync(id);
        if (existing == null)
            return NotFound();

        existing.EquipmentNumber = equipment.EquipmentNumber;
        existing.ProjectId = equipment.ProjectId;
        existing.IsActive = equipment.IsActive;

        try
        {
            _unitOfWork.Equipment.Update(existing);
            await _unitOfWork.CompleteAsync();
            return NoContent();
        }
        catch (DbUpdateException ex)
        {
            return BadRequest(new { error = "Database error while updating equipment.", detail = ex.InnerException?.Message ?? ex.Message });
        }
    }

    [Authorize(Roles = Roles.Admin)]
    [HttpDelete("{id}")]
    public async Task<IActionResult> Delete(int id)
    {
        var existing = await _unitOfWork.Equipment.GetByIdAsync(id);
        if (existing == null)
            return NotFound();

        try
        {
            _unitOfWork.Equipment.Remove(existing);
            await _unitOfWork.CompleteAsync();
            return NoContent();
        }
        catch (DbUpdateException)
        {
            return BadRequest(new { error = "Cannot delete this Equipment because it is linked to existing log entries." });
        }
    }
}
