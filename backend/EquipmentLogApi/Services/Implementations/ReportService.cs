using System.IO;
using ClosedXML.Excel;
using PdfSharpCore.Pdf;
using PdfSharpCore.Drawing;
using EquipmentLogApi.Domain.Entities;
using EquipmentLogApi.Services.Interfaces;

namespace EquipmentLogApi.Services.Implementations;

public class ReportService : IReportService
{
    // Excel Generation - Live Entries
    public byte[] GenerateLiveEntryExcel(IEnumerable<LiveEntry> entries)
    {
        using var workbook = new XLWorkbook();
        var ws = workbook.Worksheets.Add("Live Entries");

        // Title Row
        ws.Cell(1, 1).Value = "Live Entry Report";
        ws.Cell(1, 1).Style.Font.Bold = true;
        ws.Cell(1, 1).Style.Font.FontSize = 16;
        ws.Range(1, 1, 1, 7).Merge();

        // Headers
        string[] headers = { "Entry ID", "Project Name", "Equipment Number", "Operator Name", "Timestamp", "HMR/KMR Value", "Activity Type" };
        for (int i = 0; i < headers.Length; i++)
        {
            var cell = ws.Cell(3, i + 1);
            cell.Value = headers[i];
            cell.Style.Font.Bold = true;
            cell.Style.Fill.BackgroundColor = XLColor.FromHtml("#1F4E79");
            cell.Style.Font.FontColor = XLColor.White;
        }

        // Data
        int row = 4;
        foreach (var entry in entries)
        {
            ws.Cell(row, 1).Value = entry.EntryId;
            ws.Cell(row, 2).Value = entry.Project?.ProjectName ?? "N/A";
            ws.Cell(row, 3).Value = entry.Equipment?.EquipmentNumber ?? "N/A";
            ws.Cell(row, 4).Value = entry.Operator?.OperatorName ?? "N/A";
            ws.Cell(row, 5).Value = entry.EntryTimestamp.ToString("yyyy-MM-dd HH:mm:ss");
            ws.Cell(row, 6).Value = (double)entry.HMRValue;
            ws.Cell(row, 7).Value = entry.ActivityType;
            row++;
        }

        ws.Columns().AdjustToContents();
        using var stream = new MemoryStream();
        workbook.SaveAs(stream);
        return stream.ToArray();
    }

    // PDF Generation - Live Entries
    public byte[] GenerateLiveEntryPdf(IEnumerable<LiveEntry> entries)
    {
        var document = new PdfDocument();
        var page = document.AddPage();
        var gfx = XGraphics.FromPdfPage(page);

        XFont titleFont = new XFont("Arial", 16);
        XFont headerFont = new XFont("Arial", 10);
        XFont dataFont = new XFont("Arial", 9);

        // Title
        gfx.DrawString("Live Entry Report", titleFont, XBrushes.Navy, new XPoint(40, 50));
        gfx.DrawString($"Generated: {DateTime.Now:yyyy-MM-dd HH:mm:ss}", dataFont, XBrushes.Gray, new XPoint(40, 70));

        // Draw Table Headers
        int y = 100;
        gfx.DrawRectangle(new XSolidBrush(XColor.FromArgb(31, 78, 121)), 40, y, 520, 20);

        gfx.DrawString("ID", headerFont, XBrushes.White, new XPoint(45, y + 14));
        gfx.DrawString("Project Name", headerFont, XBrushes.White, new XPoint(80, y + 14));
        gfx.DrawString("Equipment", headerFont, XBrushes.White, new XPoint(180, y + 14));
        gfx.DrawString("Operator", headerFont, XBrushes.White, new XPoint(280, y + 14));
        gfx.DrawString("Timestamp", headerFont, XBrushes.White, new XPoint(380, y + 14));
        gfx.DrawString("HMR", headerFont, XBrushes.White, new XPoint(480, y + 14));
        gfx.DrawString("Activity", headerFont, XBrushes.White, new XPoint(525, y + 14));

        y += 20;

        foreach (var entry in entries)
        {
            if (y > 750) // Basic page break
            {
                page = document.AddPage();
                gfx = XGraphics.FromPdfPage(page);
                y = 50;
            }

            gfx.DrawString(entry.EntryId.ToString(), dataFont, XBrushes.Black, new XPoint(45, y + 12));
            gfx.DrawString(entry.Project?.ProjectName ?? "N/A", dataFont, XBrushes.Black, new XPoint(80, y + 12));
            gfx.DrawString(entry.Equipment?.EquipmentNumber ?? "N/A", dataFont, XBrushes.Black, new XPoint(180, y + 12));
            gfx.DrawString(entry.Operator?.OperatorName ?? "N/A", dataFont, XBrushes.Black, new XPoint(280, y + 12));
            gfx.DrawString(entry.EntryTimestamp.ToString("yyyy-MM-dd HH:mm"), dataFont, XBrushes.Black, new XPoint(380, y + 12));
            gfx.DrawString(entry.HMRValue.ToString("0.00"), dataFont, XBrushes.Black, new XPoint(480, y + 12));
            gfx.DrawString(entry.ActivityType, dataFont, XBrushes.Black, new XPoint(525, y + 12));

            gfx.DrawLine(XPens.LightGray, 40, y + 18, 560, y + 18);
            y += 20;
        }

        using var stream = new MemoryStream();
        document.Save(stream);
        return stream.ToArray();
    }

    // Excel Generation - Summary Logs
    public byte[] GenerateSummaryLogExcel(IEnumerable<SummaryLog> logs)
    {
        using var workbook = new XLWorkbook();
        var ws = workbook.Worksheets.Add("Summary Logs");

        // Title
        ws.Cell(1, 1).Value = "Summary Log Report";
        ws.Cell(1, 1).Style.Font.Bold = true;
        ws.Cell(1, 1).Style.Font.FontSize = 16;
        ws.Range(1, 1, 1, 14).Merge();

        // Headers
        string[] headers = {
            "ID", "Project", "Date", "Shift", "Equipment", "Operator",
            "Start HMR", "End HMR", "Total HMR", "Clock Hours", "Activity", "Diesel (L)", "Work Done", "Location"
        };
        for (int i = 0; i < headers.Length; i++)
        {
            var cell = ws.Cell(3, i + 1);
            cell.Value = headers[i];
            cell.Style.Font.Bold = true;
            cell.Style.Fill.BackgroundColor = XLColor.FromHtml("#1F4E79");
            cell.Style.Font.FontColor = XLColor.White;
        }

        // Data
        int row = 4;
        foreach (var log in logs)
        {
            ws.Cell(row, 1).Value = log.SummaryId;
            ws.Cell(row, 2).Value = log.Project?.ProjectName ?? "N/A";
            ws.Cell(row, 3).Value = log.Date.ToString("yyyy-MM-dd");
            ws.Cell(row, 4).Value = log.Shift;
            ws.Cell(row, 5).Value = log.Equipment?.EquipmentNumber ?? "N/A";
            ws.Cell(row, 6).Value = log.Operator?.OperatorName ?? "N/A";
            ws.Cell(row, 7).Value = log.StartHmr;
            ws.Cell(row, 8).Value = log.EndHmr;
            ws.Cell(row, 9).Value = log.TotalHmr;
            ws.Cell(row, 10).Value = (double)log.ClockHours;
            ws.Cell(row, 11).Value = log.ActivityType;
            ws.Cell(row, 12).Value = (double)log.Diesel;
            ws.Cell(row, 13).Value = log.WorkDone;
            ws.Cell(row, 14).Value = log.Location;
            row++;
        }

        ws.Columns().AdjustToContents();
        using var stream = new MemoryStream();
        workbook.SaveAs(stream);
        return stream.ToArray();
    }

    // PDF Generation - Summary Logs
    public byte[] GenerateSummaryLogPdf(IEnumerable<SummaryLog> logs)
    {
        var document = new PdfDocument();
        var page = document.AddPage();
        var gfx = XGraphics.FromPdfPage(page);

        XFont titleFont = new XFont("Arial", 14);
        XFont headerFont = new XFont("Arial", 8);
        XFont dataFont = new XFont("Arial", 8);

        // Title
        gfx.DrawString("Summary Log Report", titleFont, XBrushes.Navy, new XPoint(40, 50));
        gfx.DrawString($"Generated: {DateTime.Now:yyyy-MM-dd HH:mm}", dataFont, XBrushes.Gray, new XPoint(40, 65));

        // Draw Table Headers
        int y = 90;
        gfx.DrawRectangle(new XSolidBrush(XColor.FromArgb(31, 78, 121)), 40, y, 520, 20);

        gfx.DrawString("ID", headerFont, XBrushes.White, new XPoint(42, y + 14));
        gfx.DrawString("Date/Shift", headerFont, XBrushes.White, new XPoint(65, y + 14));
        gfx.DrawString("Equipment", headerFont, XBrushes.White, new XPoint(135, y + 14));
        gfx.DrawString("Operator", headerFont, XBrushes.White, new XPoint(205, y + 14));
        gfx.DrawString("Start", headerFont, XBrushes.White, new XPoint(285, y + 14));
        gfx.DrawString("End", headerFont, XBrushes.White, new XPoint(325, y + 14));
        gfx.DrawString("HMR", headerFont, XBrushes.White, new XPoint(365, y + 14));
        gfx.DrawString("Hours", headerFont, XBrushes.White, new XPoint(405, y + 14));
        gfx.DrawString("Diesel", headerFont, XBrushes.White, new XPoint(445, y + 14));
        gfx.DrawString("Location", headerFont, XBrushes.White, new XPoint(485, y + 14));

        y += 20;

        foreach (var log in logs)
        {
            if (y > 750)
            {
                page = document.AddPage();
                gfx = XGraphics.FromPdfPage(page);
                y = 50;
            }

            gfx.DrawString(log.SummaryId.ToString(), dataFont, XBrushes.Black, new XPoint(42, y + 12));
            gfx.DrawString($"{log.Date:MM-dd}/{log.Shift}", dataFont, XBrushes.Black, new XPoint(65, y + 12));
            gfx.DrawString(log.Equipment?.EquipmentNumber ?? "N/A", dataFont, XBrushes.Black, new XPoint(135, y + 12));
            gfx.DrawString(log.Operator?.OperatorName ?? "N/A", dataFont, XBrushes.Black, new XPoint(205, y + 12));
            gfx.DrawString(log.StartHmr.ToString("0.0"), dataFont, XBrushes.Black, new XPoint(285, y + 12));
            gfx.DrawString(log.EndHmr.ToString("0.0"), dataFont, XBrushes.Black, new XPoint(325, y + 12));
            gfx.DrawString(log.TotalHmr.ToString("0.0"), dataFont, XBrushes.Black, new XPoint(365, y + 12));
            gfx.DrawString(log.ClockHours.ToString("0.0"), dataFont, XBrushes.Black, new XPoint(405, y + 12));
            gfx.DrawString(log.Diesel.ToString("0.0"), dataFont, XBrushes.Black, new XPoint(445, y + 12));
            gfx.DrawString(log.Location ?? "-", dataFont, XBrushes.Black, new XPoint(485, y + 12));

            gfx.DrawLine(XPens.LightGray, 40, y + 18, 560, y + 18);
            y += 20;
        }

        using var stream = new MemoryStream();
        document.Save(stream);
        return stream.ToArray();
    }

    // Excel Generation - Equipment Master
    public byte[] GenerateEquipmentExcel(IEnumerable<Equipment> equipment)
    {
        using var workbook = new XLWorkbook();
        var ws = workbook.Worksheets.Add("Equipment");

        ws.Cell(1, 1).Value = "Equipment Report";
        ws.Cell(1, 1).Style.Font.Bold = true;
        ws.Cell(1, 1).Style.Font.FontSize = 16;
        ws.Range(1, 1, 1, 4).Merge();

        string[] headers = { "Equipment ID", "Equipment Number", "Project Name", "Status" };
        for (int i = 0; i < headers.Length; i++)
        {
            var cell = ws.Cell(3, i + 1);
            cell.Value = headers[i];
            cell.Style.Font.Bold = true;
            cell.Style.Fill.BackgroundColor = XLColor.FromHtml("#1F4E79");
            cell.Style.Font.FontColor = XLColor.White;
        }

        int row = 4;
        foreach (var eq in equipment)
        {
            ws.Cell(row, 1).Value = eq.EquipmentId;
            ws.Cell(row, 2).Value = eq.EquipmentNumber;
            ws.Cell(row, 3).Value = eq.Project?.ProjectName ?? "N/A";
            ws.Cell(row, 4).Value = eq.IsActive ? "Active" : "Inactive";
            row++;
        }

        ws.Columns().AdjustToContents();
        using var stream = new MemoryStream();
        workbook.SaveAs(stream);
        return stream.ToArray();
    }

    // PDF Generation - Equipment Master
    public byte[] GenerateEquipmentPdf(IEnumerable<Equipment> equipment)
    {
        var document = new PdfDocument();
        var page = document.AddPage();
        var gfx = XGraphics.FromPdfPage(page);

        XFont titleFont = new XFont("Arial", 16);
        XFont headerFont = new XFont("Arial", 10);
        XFont dataFont = new XFont("Arial", 10);

        gfx.DrawString("Equipment Report", titleFont, XBrushes.Navy, new XPoint(40, 50));
        gfx.DrawString($"Generated: {DateTime.Now:yyyy-MM-dd HH:mm}", dataFont, XBrushes.Gray, new XPoint(40, 70));

        int y = 100;
        gfx.DrawRectangle(new XSolidBrush(XColor.FromArgb(31, 78, 121)), 40, y, 520, 20);

        gfx.DrawString("Equipment ID", headerFont, XBrushes.White, new XPoint(50, y + 14));
        gfx.DrawString("Equipment Number", headerFont, XBrushes.White, new XPoint(150, y + 14));
        gfx.DrawString("Project Name", headerFont, XBrushes.White, new XPoint(300, y + 14));
        gfx.DrawString("Status", headerFont, XBrushes.White, new XPoint(460, y + 14));

        y += 20;

        foreach (var eq in equipment)
        {
            if (y > 750)
            {
                page = document.AddPage();
                gfx = XGraphics.FromPdfPage(page);
                y = 50;
            }

            gfx.DrawString(eq.EquipmentId.ToString(), dataFont, XBrushes.Black, new XPoint(50, y + 12));
            gfx.DrawString(eq.EquipmentNumber, dataFont, XBrushes.Black, new XPoint(150, y + 12));
            gfx.DrawString(eq.Project?.ProjectName ?? "N/A", dataFont, XBrushes.Black, new XPoint(300, y + 12));
            gfx.DrawString(eq.IsActive ? "Active" : "Inactive", dataFont, XBrushes.Black, new XPoint(460, y + 12));

            gfx.DrawLine(XPens.LightGray, 40, y + 18, 560, y + 18);
            y += 20;
        }

        using var stream = new MemoryStream();
        document.Save(stream);
        return stream.ToArray();
    }

    // Excel Generation - Operator Master
    public byte[] GenerateOperatorExcel(IEnumerable<Operator> operators)
    {
        using var workbook = new XLWorkbook();
        var ws = workbook.Worksheets.Add("Operators");

        ws.Cell(1, 1).Value = "Operator Report";
        ws.Cell(1, 1).Style.Font.Bold = true;
        ws.Cell(1, 1).Style.Font.FontSize = 16;
        ws.Range(1, 1, 1, 4).Merge();

        string[] headers = { "Operator ID", "Operator Name", "Mobile Number", "Status" };
        for (int i = 0; i < headers.Length; i++)
        {
            var cell = ws.Cell(3, i + 1);
            cell.Value = headers[i];
            cell.Style.Font.Bold = true;
            cell.Style.Fill.BackgroundColor = XLColor.FromHtml("#1F4E79");
            cell.Style.Font.FontColor = XLColor.White;
        }

        int row = 4;
        foreach (var op in operators)
        {
            ws.Cell(row, 1).Value = op.OperatorId;
            ws.Cell(row, 2).Value = op.OperatorName;
            ws.Cell(row, 3).Value = op.Mobile ?? "N/A";
            ws.Cell(row, 4).Value = op.IsActive ? "Active" : "Inactive";
            row++;
        }

        ws.Columns().AdjustToContents();
        using var stream = new MemoryStream();
        workbook.SaveAs(stream);
        return stream.ToArray();
    }

    // PDF Generation - Operator Master
    public byte[] GenerateOperatorPdf(IEnumerable<Operator> operators)
    {
        var document = new PdfDocument();
        var page = document.AddPage();
        var gfx = XGraphics.FromPdfPage(page);

        XFont titleFont = new XFont("Arial", 16);
        XFont headerFont = new XFont("Arial", 10);
        XFont dataFont = new XFont("Arial", 10);

        gfx.DrawString("Operator Report", titleFont, XBrushes.Navy, new XPoint(40, 50));
        gfx.DrawString($"Generated: {DateTime.Now:yyyy-MM-dd HH:mm}", dataFont, XBrushes.Gray, new XPoint(40, 70));

        int y = 100;
        gfx.DrawRectangle(new XSolidBrush(XColor.FromArgb(31, 78, 121)), 40, y, 520, 20);

        gfx.DrawString("Operator ID", headerFont, XBrushes.White, new XPoint(50, y + 14));
        gfx.DrawString("Operator Name", headerFont, XBrushes.White, new XPoint(150, y + 14));
        gfx.DrawString("Mobile Number", headerFont, XBrushes.White, new XPoint(320, y + 14));
        gfx.DrawString("Status", headerFont, XBrushes.White, new XPoint(460, y + 14));

        y += 20;

        foreach (var op in operators)
        {
            if (y > 750)
            {
                page = document.AddPage();
                gfx = XGraphics.FromPdfPage(page);
                y = 50;
            }

            gfx.DrawString(op.OperatorId.ToString(), dataFont, XBrushes.Black, new XPoint(50, y + 12));
            gfx.DrawString(op.OperatorName, dataFont, XBrushes.Black, new XPoint(150, y + 12));
            gfx.DrawString(op.Mobile ?? "N/A", dataFont, XBrushes.Black, new XPoint(320, y + 12));
            gfx.DrawString(op.IsActive ? "Active" : "Inactive", dataFont, XBrushes.Black, new XPoint(460, y + 12));

            gfx.DrawLine(XPens.LightGray, 40, y + 18, 560, y + 18);
            y += 20;
        }

        using var stream = new MemoryStream();
        document.Save(stream);
        return stream.ToArray();
    }
}
