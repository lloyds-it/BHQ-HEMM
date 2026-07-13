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
public class ProjectController : ControllerBase
{
    private readonly IUnitOfWork _unitOfWork;

    public ProjectController(IUnitOfWork unitOfWork)
    {
        _unitOfWork = unitOfWork;
    }

    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        var projects = await _unitOfWork.Projects.GetAllAsync();
        return Ok(projects);
    }

    [HttpGet("{id}")]
    public async Task<IActionResult> GetById(int id)
    {
        var project = await _unitOfWork.Projects.GetByIdAsync(id);
        if (project == null)
            return NotFound();
        return Ok(project);
    }

    [Authorize(Roles = Roles.Admin)]
    [HttpPost]
    public async Task<IActionResult> Create([FromBody] Project project)
    {
        if (!ModelState.IsValid)
            return BadRequest(ModelState);

        try
        {
            await _unitOfWork.Projects.AddAsync(project);
            await _unitOfWork.CompleteAsync();
            return CreatedAtAction(nameof(GetById), new { id = project.ProjectId }, project);
        }
        catch (DbUpdateException ex)
        {
            return BadRequest(new { error = "Database error while creating project.", detail = ex.InnerException?.Message ?? ex.Message });
        }
    }

    [Authorize(Roles = Roles.Admin)]
    [HttpPut("{id}")]
    public async Task<IActionResult> Update(int id, [FromBody] Project project)
    {
        if (id != project.ProjectId)
            return BadRequest("ID mismatch");

        if (!ModelState.IsValid)
            return BadRequest(ModelState);

        var existing = await _unitOfWork.Projects.GetByIdAsync(id);
        if (existing == null)
            return NotFound();

        existing.ProjectName = project.ProjectName;

        try
        {
            _unitOfWork.Projects.Update(existing);
            await _unitOfWork.CompleteAsync();
            return NoContent();
        }
        catch (DbUpdateException ex)
        {
            return BadRequest(new { error = "Database error while updating project.", detail = ex.InnerException?.Message ?? ex.Message });
        }
    }

    [Authorize(Roles = Roles.Admin)]
    [HttpDelete("{id}")]
    public async Task<IActionResult> Delete(int id)
    {
        var existing = await _unitOfWork.Projects.GetByIdAsync(id);
        if (existing == null)
            return NotFound();

        try
        {
            _unitOfWork.Projects.Remove(existing);
            await _unitOfWork.CompleteAsync();
            return NoContent();
        }
        catch (DbUpdateException)
        {
            return BadRequest(new { error = "Cannot delete this Project because it is linked to existing equipment or log entries." });
        }
    }
}
