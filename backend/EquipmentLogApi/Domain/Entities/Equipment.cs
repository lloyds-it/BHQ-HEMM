using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace EquipmentLogApi.Domain.Entities;

public class Equipment
{
    [Key]
    public int EquipmentId { get; set; }

    [Required]
    [MaxLength(100)]
    public string EquipmentNumber { get; set; } = string.Empty;

    [Required]
    public int ProjectId { get; set; }

    [ForeignKey("ProjectId")]
    public Project? Project { get; set; }

    public bool IsActive { get; set; } = true;
}
