using System.Data;
using System.Data.SqlClient;
using System.Text.Json.Serialization;
using ClosedXML.Excel;

namespace Seats.Api.Services
{
    public class SeatsService
    {
        private readonly IConfiguration _cfg;
        private readonly IWebHostEnvironment _env;

        public SeatsService(IConfiguration cfg, IWebHostEnvironment env)
        {
            _cfg = cfg;
            _env = env;
        }

        private string GetSql(string fileName)
        {
            var path = Path.Combine(_env.ContentRootPath, "Sql", fileName);
            return File.ReadAllText(path);
        }

        private static DateTime StartOfDay(DateOnly d) => d.ToDateTime(TimeOnly.MinValue);
        private static DateTime EndOfDay(DateOnly d) => d.ToDateTime(new TimeOnly(23, 59, 59, 997));

        public async Task<DataTable> GetFlightsSeatsReportAsync(DateOnly start, DateOnly end)
        {
            var sql = GetSql("FlightsSeats_ClassessOfServices.sql");
            return await ExecuteReportAsync("NavCS", sql, start, end);
        }

        public async Task<DataTable> GetFlightsSeatsDetailsReportAsync(DateOnly start, DateOnly end)
        {
            var sql = GetSql("PassengersCountWithFares.sql");
            return await ExecuteReportAsync("NavCS", sql, start, end);
        }

        public async Task<SerializableReport> GetFlightsSeatsReportForApiAsync(DateOnly start, DateOnly end)
        {
            var dt = await GetFlightsSeatsReportAsync(start, end);
            return ToSerializable(dt);
        }

        public async Task<SerializableReport> GetFlightsSeatsDetailsReportForApiAsync(DateOnly start, DateOnly end)
        {
            var dt = await GetFlightsSeatsDetailsReportAsync(start, end);
            return ToSerializable(dt);
        }

        public async Task<byte[]> GetFlightsSeatsExcelAsync(DateOnly start, DateOnly end, bool detailed)
        {
            var dt = detailed
                ? await GetFlightsSeatsDetailsReportAsync(start, end)
                : await GetFlightsSeatsReportAsync(start, end);

            using var wb = new XLWorkbook();
            wb.Worksheets.Add(dt, "Report");
            using var ms = new MemoryStream();
            wb.SaveAs(ms);
            return ms.ToArray();
        }

        private async Task<DataTable> ExecuteReportAsync(string connName, string sql, DateOnly start, DateOnly end)
        {
            var dt = new DataTable();
            await using var conn = new SqlConnection(_cfg.GetConnectionString(connName));
            await using var cmd = new SqlCommand(sql, conn)
            {
                CommandTimeout = 5000
            };
            cmd.Parameters.AddWithValue("@StartDate", StartOfDay(start));
            cmd.Parameters.AddWithValue("@EndDate", EndOfDay(end));

            await conn.OpenAsync();
            using var da = new SqlDataAdapter(cmd);
            da.Fill(dt);
            return dt;
        }

        private static SerializableReport ToSerializable(DataTable table)
        {
            var cols = table.Columns.Cast<DataColumn>()
                .Select(c => new ColumnDto
                {
                    Name = c.ColumnName,
                    DataType = c.DataType.FullName ?? "System.Object", //
                    AllowNull = c.AllowDBNull,
                    MaxLength = c.MaxLength
                })
                .ToList();

            var rows = table.Rows.Cast<DataRow>()
                .Select(r =>
                {
                    var dict = new Dictionary<string, object?>(table.Columns.Count, StringComparer.OrdinalIgnoreCase);
                    foreach (DataColumn c in table.Columns)
                    {
                        var val = r[c];
                        dict[c.ColumnName] = val == DBNull.Value ? null : val;
                    }
                    return dict;
                })
                .ToList();

            return new SerializableReport { Columns = cols, Rows = rows };
        }
    }

    public sealed class SerializableReport
    {
        public List<ColumnDto> Columns { get; set; } = new();
        public List<Dictionary<string, object?>> Rows { get; set; } = new();
    }

    public sealed class ColumnDto
    {
        public string Name { get; set; } = "";
        public string DataType { get; set; } = "";   
        public bool AllowNull { get; set; }
        public int MaxLength { get; set; }
    }
}
