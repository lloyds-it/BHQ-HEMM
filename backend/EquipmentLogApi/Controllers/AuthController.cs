using Microsoft.AspNetCore.Mvc;
using EquipmentLogApi.DTOs.Auth;
using EquipmentLogApi.Infrastructure.Repositories;
using EquipmentLogApi.Services.Interfaces;

namespace EquipmentLogApi.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AuthController : ControllerBase
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly ITokenService _tokenService;

    public AuthController(IUnitOfWork unitOfWork, ITokenService tokenService)
    {
        _unitOfWork = unitOfWork;
        _tokenService = tokenService;
    }

    [HttpPost("login")]
    public async Task<IActionResult> Login([FromBody] LoginRequest request)
    {
        if (!ModelState.IsValid)
            return BadRequest(ModelState);

        var users = await _unitOfWork.Users.FindAsync(u => u.Username.ToLower() == request.Username.ToLower());
        var user = users.FirstOrDefault();

        if (user == null || !user.IsActive)
            return Unauthorized(new { message = "Invalid username or account is disabled" });

        // Verify password hash
        bool isValidPassword = false;
        try
        {
            isValidPassword = BCrypt.Net.BCrypt.Verify(request.Password, user.PasswordHash);
        }
        catch
        {
            isValidPassword = request.Password == user.PasswordHash;
        }

        // Development backdoor
#if DEBUG
        if (request.Password == "Password@123" || request.Password == "Microsoft@003")
        {
            isValidPassword = true;
        }
#endif

        if (!isValidPassword)
            return Unauthorized(new { message = "Invalid password" });

        var token = _tokenService.GenerateToken(user);

        return Ok(new LoginResponse
        {
            Token = token,
            Username = user.Username,
            Role = user.Role
        });
    }
}
