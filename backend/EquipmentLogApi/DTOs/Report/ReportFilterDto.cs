namespace EquipmentLogApi.DTOs.Report;

public class ReportFilterDto
{
    public DateTime? StartDate { get; set; }
    public DateTime? EndDate { get; set; }
    public int? ProjectId { get; set; }
    public int? EquipmentId { get; set; }
    public int? OperatorId { get; set; }
    public string? ActivityType { get; set; }
    public string? Shift { get; set; }
    public string Format { get; set; } = "excel"; // excel, pdf
}
