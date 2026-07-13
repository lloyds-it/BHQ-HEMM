using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace EquipmentLogApi.Domain.Entities;

public class SummaryLog
{
    [Key]
    public int SummaryId { get; set; }

    [Required]
    public int ProjectId { get; set; }

    [ForeignKey("ProjectId")]
    public Project? Project { get; set; }

    [Required]
    public DateTime Date { get; set; }

    [Required]
    [MaxLength(50)]
    public string Shift { get; set; } = string.Empty;

    [Required]
    public int EquipmentId { get; set; }

    [ForeignKey("EquipmentId")]
    public Equipment? Equipment { get; set; }

    [Required]
    public int OperatorId { get; set; }

    [ForeignKey("OperatorId")]
    public Operator? Operator { get; set; }

    [Required]
    public DateTime StartTimestamp { get; set; }

    [Required]
    public DateTime EndTimestamp { get; set; }

    [Required]
    public double StartHmr { get; set; }

    [Required]
    public double EndHmr { get; set; }

    [Required]
    public double TotalHmr { get; set; }

    [Required]
    public double ClockHours { get; set; }

    [Required]
    [MaxLength(50)]
    public string ActivityType { get; set; } = string.Empty;

    [MaxLength(255)]
    public string? WorkDone { get; set; }

    [MaxLength(255)]
    public string? Location { get; set; }

    public double Diesel { get; set; } = 0.00;

    public double HydraulicOil { get; set; } = 0.00;

    public double EngineOil { get; set; } = 0.00;

    public double TransmissionOil { get; set; } = 0.00;

    public double GearOil { get; set; } = 0.00;

    public string? Remarks { get; set; }

    [MaxLength(100)]
    public string CreatedBy { get; set; } = string.Empty;

    [NotMapped]
    public DateTime CreatedDate { get; set; } = DateTime.UtcNow;
}
