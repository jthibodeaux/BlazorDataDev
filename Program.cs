using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using BlazorDbEditor.Services;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddRazorPages();
builder.Services.AddServerSideBlazor();

// Add Windows Authentication
builder.Services.AddAuthentication(Microsoft.AspNetCore.Authentication.Negotiate.NegotiateDefaults.AuthenticationScheme)
    .AddNegotiate();
builder.Services.AddAuthorization();
builder.Services.AddScoped<Microsoft.AspNetCore.Authentication.IClaimsTransformation, RoleClaimsTransformation>();

// Register Dapper-based services
builder.Services.AddScoped<IDynamicDbService, DynamicDbService>();
builder.Services.AddScoped<ITableService, TableService>();

// Register in-memory data store as singleton (shared across all requests)
builder.Services.AddSingleton<IInMemoryDataStore, InMemoryDataStore>();

// Register SQLite query service as singleton (shared in-memory database)
builder.Services.AddSingleton<ISqliteQueryService, SqliteQueryService>();

// Register startup automation service
builder.Services.AddScoped<IStartupAutomationService, StartupAutomationService>();

// Register live data service
builder.Services.AddScoped<ILiveDataService, LiveDataService>();

// Register external database explorer service
builder.Services.AddSingleton<IExternalDbExplorerService, ExternalDbExplorerService>();

// Register DDL merger service
builder.Services.AddSingleton<IDdlMergerService, DdlMergerService>();

// Add API controllers
builder.Services.AddControllers();

// Add Swagger/OpenAPI
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new Microsoft.OpenApi.Models.OpenApiInfo
    {
        Title = "Blazor DataDev API",
        Version = "v2.0.0",
        Description = "Local database testing platform - fetch from multiple DBs, merge, test locally, generate migration scripts"
    });
});

var app = builder.Build();

// Configure the HTTP request pipeline.
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Error");
    app.UseHsts();
}

app.UseHttpsRedirection();
app.UseStaticFiles();
app.UseRouting();

// Enable authentication and authorization
app.UseAuthentication();
app.UseAuthorization();

// Enable Swagger in all environments for testing
app.UseSwagger();
app.UseSwaggerUI(c =>
{
 c.SwaggerEndpoint("/swagger/v1/swagger.json", "Blazor DataDev API v2.0");
    c.RoutePrefix = "swagger"; // Access at /swagger
    c.DocumentTitle = "Blazor DataDev - API Documentation";
});

// Map API controllers
app.MapControllers();

// Map Blazor
app.MapBlazorHub();
app.MapFallbackToPage("/_Host");

app.Run();
