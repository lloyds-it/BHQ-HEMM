using EquipmentLogApi.Domain.Entities;

namespace EquipmentLogApi.Services.Interfaces;

public interface ITokenService
{
    string GenerateToken(User user);
}
