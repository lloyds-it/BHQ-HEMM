using System.ComponentModel.DataAnnotations;

namespace EquipmentLogApi.Domain.Entities;

public class Project
{
    [Key]
    public int ProjectId { get; set; }

    [Required]
    [MaxLength(150)]
    public string ProjectName { get; set; } = string.Empty;
}
