using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace EquipmentLogApi.Domain.Entities;

public class LiveEntry
{
    [Key]
    public int EntryId { get; set; }

    [Required]
    public int ProjectId { get; set; }

    [ForeignKey("ProjectId")]
    public Project? Project { get; set; }

    [Required]
    public int EquipmentId { get; set; }

    [ForeignKey("EquipmentId")]
    public Equipment? Equipment { get; set; }

    [Required]
    public int OperatorId { get; set; }

    [ForeignKey("OperatorId")]
    public Operator? Operator { get; set; }

    [Required]
    public DateTime EntryTimestamp { get; set; }

    [Required]
    public double HMRValue { get; set; }

    [Required]
    [MaxLength(50)]
    public string ActivityType { get; set; } = string.Empty; // Running, Idle, Breakdown, Stoppage

    [MaxLength(100)]
    public string CreatedBy { get; set; } = string.Empty;

    public DateTime CreatedDate { get; set; } = DateTime.UtcNow;
}
