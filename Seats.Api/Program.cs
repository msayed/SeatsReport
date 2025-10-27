using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using Seats.Api.Services;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;

var builder = WebApplication.CreateBuilder(args);

// Services
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(o =>
{
    o.SwaggerDoc("v1", new OpenApiInfo { Title = "Seats API", Version = "v1" });

    // Enable "Authorize" button with Bearer token
    var scheme = new OpenApiSecurityScheme
    {
        Name = "Authorization",
        Type = SecuritySchemeType.Http,
        Scheme = "bearer",
        BearerFormat = "JWT",
        In = ParameterLocation.Header,
        Description = "Enter: Bearer {your JWT}",
        Reference = new OpenApiReference
        {
            Type = ReferenceType.SecurityScheme,
            Id = "Bearer"
        }
    };
    o.AddSecurityDefinition("Bearer", scheme);
    o.AddSecurityRequirement(new OpenApiSecurityRequirement
    {
        { scheme, Array.Empty<string>() }
    });
});

builder.Services.AddScoped<SeatsService>();
builder.Services.AddScoped<AuthService>();

// CORS (dev)
builder.Services.AddCors(o => o.AddDefaultPolicy(p => p
    .AllowAnyOrigin()
    .AllowAnyHeader()
    .AllowAnyMethod()));


// ===== JWT Auth =====
var jwtSection = builder.Configuration.GetSection("Jwt");
var issuer = jwtSection["Issuer"] ?? throw new InvalidOperationException("Jwt:Issuer is missing");
var audience = jwtSection["Audience"] ?? throw new InvalidOperationException("Jwt:Audience is missing");
var key = jwtSection["Key"] ?? throw new InvalidOperationException("Jwt:Key is missing");
var signingKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(key));

builder.Services
    .AddAuthentication(options =>
    {
        options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
        options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
    })
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            ValidIssuer = issuer,
            ValidAudience = audience,
            IssuerSigningKey = signingKey,
            ClockSkew = TimeSpan.FromMinutes(2)
        };
    });

builder.Services.AddAuthorization();

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();
app.UseCors(o => o
    .AllowAnyOrigin()
    .AllowAnyHeader()
    .AllowAnyMethod());
app.UseAuthentication();
app.UseAuthorization();


// ===== Auth endpoint =====
app.MapPost("/api/auth/token", async ([FromBody] LoginRequest req, AuthService authService, IConfiguration cfg) =>
{
    if (string.IsNullOrWhiteSpace(req.Username) || string.IsNullOrWhiteSpace(req.Password))
    {
        return Results.BadRequest(new { error = "Username and password are required." });
    }

    var user = await authService.ValidateUserAsync(req.Username, req.Password);
    if (user is null)
    {
        return Results.Unauthorized();
    }

    var jwtSection = cfg.GetSection("Jwt");
    var issuer = jwtSection["Issuer"]!;
    var audience = jwtSection["Audience"]!;
    var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtSection["Key"]!));
    var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

    var claims = new List<Claim>
    {
        new Claim(JwtRegisteredClaimNames.Sub, user.Username),
        new Claim(ClaimTypes.Name, user.Username),
        new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString()),
    };

    if (!string.IsNullOrWhiteSpace(user.FullName))
    {
        claims.Add(new Claim("full_name", user.FullName));
    }

    var token = new JwtSecurityToken(
        issuer: issuer,
        audience: audience,
        claims: claims,
        expires: DateTime.UtcNow.AddHours(8),
        signingCredentials: creds);

    var jwt = new JwtSecurityTokenHandler().WriteToken(token);
    return Results.Ok(new { access_token = jwt, token_type = "Bearer", username = user.Username, fullname = user.FullName });
})
.WithName("GetToken")
.WithTags("Auth");


// ===== Reports (JSON-safe: no System.Type) =====
app.MapGet("/api/seats/report", async (
    [FromQuery] DateOnly start,
    [FromQuery] DateOnly end,
    SeatsService svc) =>
    Results.Ok(await svc.GetFlightsSeatsReportForApiAsync(start, end))
).RequireAuthorization();

app.MapGet("/api/seats/report-details", async (
    [FromQuery] DateOnly start,
    [FromQuery] DateOnly end,
    SeatsService svc) =>
    Results.Ok(await svc.GetFlightsSeatsDetailsReportForApiAsync(start, end))
).RequireAuthorization();


// ===== Excel endpoints (تظل تستخدم DataTable داخلياً) =====
app.MapGet("/api/seats/report.xlsx", async (
    [FromQuery] DateOnly start,
    [FromQuery] DateOnly end,
    SeatsService svc) =>
{
    var wbBytes = await svc.GetFlightsSeatsExcelAsync(start, end, detailed: false);
    return Results.File(wbBytes,
        "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        "seats-report.xlsx");
}).RequireAuthorization();

app.MapGet("/api/seats/report-details.xlsx", async (
    [FromQuery] DateOnly start,
    [FromQuery] DateOnly end,
    SeatsService svc) =>
{
    var wbBytes = await svc.GetFlightsSeatsExcelAsync(start, end, detailed: true);
    return Results.File(wbBytes,
        "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        "seats-report-details.xlsx");
}).RequireAuthorization();

app.Run();

record LoginRequest(string Username, string Password);
