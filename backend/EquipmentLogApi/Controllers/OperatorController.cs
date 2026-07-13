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
public class OperatorController : ControllerBase
{
    private readonly IUnitOfWork _unitOfWork;

    public OperatorController(IUnitOfWork unitOfWork)
    {
        _unitOfWork = unitOfWork;
    }

    [HttpGet]
    public async Task<IActionResult> GetAll([FromQuery] string? search)
    {
        var operators = await _unitOfWork.Operators.GetAllAsync();

        if (!string.IsNullOrEmpty(search))
        {
            search = search.Trim();
            operators = operators.Where(op => 
                op.OperatorName.Contains(search, StringComparison.OrdinalIgnoreCase) ||
                (op.Mobile != null && op.Mobile.Contains(search))
            );
        }

        return Ok(operators);
    }

    [HttpGet("{id}")]
    public async Task<IActionResult> GetById(int id)
    {
        var op = await _unitOfWork.Operators.GetByIdAsync(id);
        if (op == null)
            return NotFound();
        return Ok(op);
    }

    [Authorize(Roles = Roles.Admin)]
    [HttpPost]
    public async Task<IActionResult> Create([FromBody] Operator op)
    {
        if (!ModelState.IsValid)
            return BadRequest(ModelState);

        try
        {
            await _unitOfWork.Operators.AddAsync(op);
            await _unitOfWork.CompleteAsync();
            return CreatedAtAction(nameof(GetById), new { id = op.OperatorId }, op);
        }
        catch (DbUpdateException ex)
        {
            return BadRequest(new { error = "Database error while creating operator.", detail = ex.InnerException?.Message ?? ex.Message });
        }
    }

    [Authorize(Roles = Roles.Admin)]
    [HttpPut("{id}")]
    public async Task<IActionResult> Update(int id, [FromBody] Operator op)
    {
        if (id != op.OperatorId)
            return BadRequest("ID mismatch");

        if (!ModelState.IsValid)
            return BadRequest(ModelState);

        var existing = await _unitOfWork.Operators.GetByIdAsync(id);
        if (existing == null)
            return NotFound();

        existing.OperatorName = op.OperatorName;
        existing.Mobile = op.Mobile;
        existing.IsActive = op.IsActive;

        try
        {
            _unitOfWork.Operators.Update(existing);
            await _unitOfWork.CompleteAsync();
            return NoContent();
        }
        catch (DbUpdateException ex)
        {
            return BadRequest(new { error = "Database error while updating operator.", detail = ex.InnerException?.Message ?? ex.Message });
        }
    }

    [Authorize(Roles = Roles.Admin)]
    [HttpDelete("{id}")]
    public async Task<IActionResult> Delete(int id)
    {
        var existing = await _unitOfWork.Operators.GetByIdAsync(id);
        if (existing == null)
            return NotFound();

        try
        {
            _unitOfWork.Operators.Remove(existing);
            await _unitOfWork.CompleteAsync();
            return NoContent();
        }
        catch (DbUpdateException)
        {
            return BadRequest(new { error = "Cannot delete this Operator because they are linked to existing log entries." });
        }
    }
}
