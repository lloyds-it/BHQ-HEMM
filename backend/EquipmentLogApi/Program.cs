using System.Threading.RateLimiting;
using System.Text;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using EquipmentLogApi.Infrastructure.Data;
using EquipmentLogApi.Infrastructure.Repositories;
using EquipmentLogApi.Services.Implementations;
using EquipmentLogApi.Services.Interfaces;
using EquipmentLogApi.Domain.Entities;
using Microsoft.AspNetCore.HttpOverrides;

var builder = WebApplication.CreateBuilder(args);

// 1. Database Connection
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");

builder.Services.AddDbContext<ApplicationDbContext>(options =>
    options.UseSqlServer(connectionString));

// 2. Dependency Injection Services
builder.Services.AddScoped<IUnitOfWork, UnitOfWork>();
builder.Services.AddScoped<ITokenService, TokenService>();
builder.Services.AddScoped<IReportService, ReportService>();

// 3. JWT Authentication Configuration
var jwtKey = builder.Configuration["Jwt:Key"] ?? "SUPER_SECRET_KEY_FOR_EQUIPMENT_LOG_API_DEVELOPMENT_2026";
var issuer = builder.Configuration["Jwt:Issuer"] ?? "EquipmentLogApi";
var audience = builder.Configuration["Jwt:Audience"] ?? "EquipmentLogMobileApp";

builder.Services.AddAuthentication(options =>
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
        IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtKey))
    };

    options.Events = new JwtBearerEvents
    {
        OnMessageReceived = context =>
        {
            var accessToken = context.Request.Query["token"];
            var path = context.HttpContext.Request.Path;
            if (!string.IsNullOrEmpty(accessToken) && path.StartsWithSegments("/api/Report"))
            {
                context.Token = accessToken;
            }
            return Task.CompletedTask;
        }
    };
});

builder.Services.AddAuthorization();

// 4. Rate Limiting & Security
builder.Services.AddRateLimiter(options =>
{
    options.GlobalLimiter = PartitionedRateLimiter.Create<HttpContext, string>(httpContext =>
        RateLimitPartition.GetFixedWindowLimiter(
            partitionKey: httpContext.Connection.RemoteIpAddress?.ToString() ?? httpContext.Request.Headers.Host.ToString(),
            factory: partition => new FixedWindowRateLimiterOptions
            {
                AutoReplenishment = true,
                PermitLimit = 100, // 100 requests
                QueueLimit = 0,
                Window = TimeSpan.FromMinutes(1)
            }));
    options.RejectionStatusCode = 429;
});

// 5. Controllers & CORS
builder.Services.AddControllers();
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", policy =>
    {
        policy.WithOrigins("https://taskai.lloyds.in")
              .SetIsOriginAllowed(origin => new Uri(origin).Host == "localhost" || new Uri(origin).Host == "127.0.0.1")
              .AllowAnyMethod()
              .AllowAnyHeader();
    });
});

// 5. Swagger/OpenAPI Configuration with JWT Support
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new OpenApiInfo 
    { 
        Title = "Equipment Log Web API", 
        Version = "v1",
        Description = "Production-ready Web API for Mining Equipment Log Tracking"
    });

    c.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Name = "Authorization",
        Type = SecuritySchemeType.ApiKey,
        Scheme = "Bearer",
        BearerFormat = "JWT",
        In = ParameterLocation.Header,
        Description = "JWT Authorization header using the Bearer scheme. Example: \"Authorization: Bearer {token}\""
    });

    c.AddSecurityRequirement(new OpenApiSecurityRequirement
    {
        {
            new OpenApiSecurityScheme
            {
                Reference = new OpenApiReference
                {
                    Type = ReferenceType.SecurityScheme,
                    Id = "Bearer"
                }
            },
            Array.Empty<string>()
        }
    });
});

var app = builder.Build();

// Configure the HTTP request pipeline.
app.UseForwardedHeaders(new ForwardedHeadersOptions
{
    ForwardedHeaders = ForwardedHeaders.XForwardedFor | ForwardedHeaders.XForwardedProto
});

app.UsePathBase("/hemm/api");

app.Use(async (context, next) =>
{
    context.Response.Headers.Append("X-Content-Type-Options", "nosniff");
    context.Response.Headers.Append("X-Frame-Options", "DENY");
    context.Response.Headers.Append("X-XSS-Protection", "1; mode=block");
    await next();
});

if (app.Environment.IsDevelopment()) // Enable Swagger only in development environment
{
    app.UseSwagger();
    app.UseSwaggerUI(c =>
    {
        c.SwaggerEndpoint("/swagger/v1/swagger.json", "Equipment Log API v1");
    });
}

app.UseRateLimiter();
app.UseCors("AllowAll");
app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();

using (var scope = app.Services.CreateScope())
{
    try
    {
        var db = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
        
        // 1. Ensure the SQL Database and its tables/constraints are created
        Console.WriteLine("Ensuring database schema is created...");
        await db.Database.EnsureCreatedAsync();
        Console.WriteLine("Database schema verified/created successfully.");

        // 2. Seed default data if database is empty
        if (!await db.Users.AnyAsync())
        {
            Console.WriteLine("Database is empty. Seeding default configuration and master data...");

            // Seed Projects
            var projects = new List<Project>
            {
                new() { ProjectName = "BHQ Hedri" },
                new() { ProjectName = "BHQ East Pit" },
                new() { ProjectName = "BHQ West Pit" }
            };
            await db.Projects.AddRangeAsync(projects);
            await db.SaveChangesAsync(); // Generates IDs (1, 2, 3)

            // Seed Operators
            var operators = new List<Operator>
            {
                new() { OperatorName = "Rajesh Kumar", Mobile = "9876543210", IsActive = true },
                new() { OperatorName = "Amit Sharma", Mobile = "8765432109", IsActive = true },
                new() { OperatorName = "Vijay Yadav", Mobile = "7654321098", IsActive = true },
                new() { OperatorName = "Sunil Singh", Mobile = "6543210987", IsActive = true }
            };
            await db.Operators.AddRangeAsync(operators);
            await db.SaveChangesAsync(); // Generates IDs (1, 2, 3, 4)

            // Seed Equipment (referencing projects)
            var equipment = new List<Equipment>
            {
                new() { EquipmentNumber = "EQ-TR-2034", ProjectId = projects[0].ProjectId, IsActive = true },
                new() { EquipmentNumber = "EQ-TR-4567", ProjectId = projects[0].ProjectId, IsActive = true },
                new() { EquipmentNumber = "EQ-TR-8812", ProjectId = projects[0].ProjectId, IsActive = true },
                new() { EquipmentNumber = "EQ-TR-9051", ProjectId = projects[1].ProjectId, IsActive = true },
                new() { EquipmentNumber = "EQ-TR-1122", ProjectId = projects[1].ProjectId, IsActive = true },
                new() { EquipmentNumber = "EQ-TR-3344", ProjectId = projects[2].ProjectId, IsActive = true }
            };
            await db.Equipment.AddRangeAsync(equipment);
            await db.SaveChangesAsync(); // Generates IDs (1, 2, 3, 4, 5, 6)

            // Seed Users (Admin, Supervisor, Operator)
            // Default passwords: 'Password@123' (BCrypt hashed)
            var users = new List<User>
            {
                new() { Username = "admin", PasswordHash = "$2a$11$e09ZtA8/OUNj.9LhS.Xk/O7N0l/RuxoU/7G2y5x0l217Wb25Gg86K", Role = "Admin", IsActive = true },
                new() { Username = "supervisor", PasswordHash = "$2a$11$e09ZtA8/OUNj.9LhS.Xk/O7N0l/RuxoU/7G2y5x0l217Wb25Gg86K", Role = "Supervisor", IsActive = true },
                new() { Username = "operator", PasswordHash = "$2a$11$e09ZtA8/OUNj.9LhS.Xk/O7N0l/RuxoU/7G2y5x0l217Wb25Gg86K", Role = "Operator", IsActive = true }
            };
            await db.Users.AddRangeAsync(users);
            await db.SaveChangesAsync(); // Generates IDs (1, 2, 3)

            // Seed a default LiveEntry & SummaryLog for validation
            var defaultLiveEntry = new LiveEntry
            {
                ProjectId = projects[0].ProjectId,
                EquipmentId = equipment[0].EquipmentId,
                OperatorId = operators[0].OperatorId,
                EntryTimestamp = DateTime.UtcNow.AddHours(-1),
                HMRValue = 1250.50,
                ActivityType = "Running",
                CreatedBy = "supervisor",
                CreatedDate = DateTime.UtcNow
            };
            await db.LiveEntries.AddAsync(defaultLiveEntry);

            var defaultSummaryLog = new SummaryLog
            {
                ProjectId = projects[0].ProjectId,
                Date = DateTime.UtcNow.Date,
                Shift = "Day",
                EquipmentId = equipment[0].EquipmentId,
                OperatorId = operators[0].OperatorId,
                StartTimestamp = DateTime.UtcNow.AddHours(-8),
                EndTimestamp = DateTime.UtcNow.AddHours(-4),
                StartHmr = 1242.50,
                EndHmr = 1246.50,
                TotalHmr = 4.00,
                ClockHours = 4.00,
                ActivityType = "Running",
                WorkDone = "Excavation Work",
                Location = "North Face",
                Diesel = 150.00,
                HydraulicOil = 10.00,
                EngineOil = 5.00,
                TransmissionOil = 0.00,
                GearOil = 0.00,
                Remarks = "Shift completed smoothly",
                CreatedBy = "supervisor",
                CreatedDate = DateTime.UtcNow
            };
            await db.SummaryLogs.AddAsync(defaultSummaryLog);
            await db.SaveChangesAsync();

            Console.WriteLine("Database seeding completed successfully!");
        }
        else
        {
            Console.WriteLine("Database already contains data. Skipping seeding.");
        }
    }
    catch (Exception ex)
    {
        Console.WriteLine($"Database initialization failed: {ex.Message}");
        if (ex.InnerException != null)
        {
            Console.WriteLine($"Inner Exception: {ex.InnerException.Message}");
        }
    }
}

app.Run();
