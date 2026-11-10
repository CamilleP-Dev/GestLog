using GestLog.Api.Data;
using GestLog.Api.Endpoints;
using GestLog.Api.Errors;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
// Learn more about configuring OpenAPI at https://aka.ms/aspnet/openapi
builder.Services.AddOpenApi();
builder.Services.AddProblemDetails();
builder.Services.AddExceptionHandler<ErreurMetierHandler>();
builder.Services.AddSingleton<OracleConnectionFactory>();
builder.Services.AddScoped<IDemandeurRepository, DemandeurRepository>();
builder.Services.AddScoped<IDemandeRepository, DemandeRepository>();

var app = builder.Build();

app.UseExceptionHandler();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

app.MapSante();
app.MapDemandeurs();
app.MapDemandes();

app.Run();
