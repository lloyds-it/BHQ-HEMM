using EquipmentLogApi.Domain.Entities;

namespace EquipmentLogApi.Services.Interfaces;

public interface IReportService
{
    byte[] GenerateLiveEntryExcel(IEnumerable<LiveEntry> entries);
    byte[] GenerateLiveEntryPdf(IEnumerable<LiveEntry> entries);

    byte[] GenerateSummaryLogExcel(IEnumerable<SummaryLog> logs);
    byte[] GenerateSummaryLogPdf(IEnumerable<SummaryLog> logs);

    byte[] GenerateEquipmentExcel(IEnumerable<Equipment> equipment);
    byte[] GenerateEquipmentPdf(IEnumerable<Equipment> equipment);

    byte[] GenerateOperatorExcel(IEnumerable<Operator> operators);
    byte[] GenerateOperatorPdf(IEnumerable<Operator> operators);
}
