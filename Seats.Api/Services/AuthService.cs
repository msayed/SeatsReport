using System.Data;
using System.Data.SqlClient;

namespace Seats.Api.Services;

public sealed class AuthService
{
    private readonly IConfiguration _configuration;

    public AuthService(IConfiguration configuration)
    {
        _configuration = configuration;
    }

    public async Task<AuthenticatedUser?> ValidateUserAsync(string username, string password, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(username) || string.IsNullOrWhiteSpace(password))
        {
            return null;
        }

        var connectionString = _configuration.GetConnectionString("AuthDb")
            ?? _configuration.GetConnectionString("NavCS")
            ?? throw new InvalidOperationException("Connection string 'AuthDb' is not configured.");

        const string sql = @"SELECT TOP (1) ID, Username, Password, Fullname, isDisable
                              FROM tbl_Settings
                              WHERE Username = @Username";

        await using var conn = new SqlConnection(connectionString);
        await conn.OpenAsync(cancellationToken);

        await using var cmd = new SqlCommand(sql, conn)
        {
            CommandType = CommandType.Text
        };

        var usernameParam = cmd.Parameters.Add("@Username", SqlDbType.NVarChar, 50);
        usernameParam.Value = username;

        await using var reader = await cmd.ExecuteReaderAsync(CommandBehavior.SingleRow, cancellationToken);
        if (!await reader.ReadAsync(cancellationToken))
        {
            return null;
        }

        if (!reader.IsDBNull(reader.GetOrdinal("isDisable")) && reader.GetBoolean(reader.GetOrdinal("isDisable")))
        {
            return null;
        }

        var storedPassword = reader.IsDBNull(reader.GetOrdinal("Password"))
            ? string.Empty
            : reader.GetString(reader.GetOrdinal("Password"));

        if (!string.Equals(storedPassword, password))
        {
            return null;
        }

        var id = reader.GetInt32(reader.GetOrdinal("ID"));
        var dbUsername = reader.IsDBNull(reader.GetOrdinal("Username"))
            ? username
            : reader.GetString(reader.GetOrdinal("Username"));
        var fullName = reader.IsDBNull(reader.GetOrdinal("Fullname"))
            ? string.Empty
            : reader.GetString(reader.GetOrdinal("Fullname"));

        return new AuthenticatedUser(id, dbUsername, fullName);
    }
}

public sealed record AuthenticatedUser(int Id, string Username, string FullName);
