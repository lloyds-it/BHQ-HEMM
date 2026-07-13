using System.ComponentModel.DataAnnotations;

namespace EquipmentLogApi.Domain.Entities;

public class Operator
{
    [Key]
    public int OperatorId { get; set; }

    [Required]
    [MaxLength(150)]
    public string OperatorName { get; set; } = string.Empty;

    [MaxLength(20)]
    public string? Mobile { get; set; }

    public bool IsActive { get; set; } = true;
}
