namespace EquipmentLogApi.Domain.Constants;

public static class ActivityTypes
{
    public const string Running = "Running";
    public const string Idle = "Idle";
    public const string Breakdown = "Breakdown";
    public const string Stoppage = "Stoppage";

    public static readonly string[] All = [Running, Idle, Breakdown, Stoppage];
}
