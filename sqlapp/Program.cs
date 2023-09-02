using Azure.Identity;
using Azure.Security.KeyVault.Secrets;
using Microsoft.AspNetCore.Builder;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using sqlapp.Services;
using StackExchange.Redis;

var builder = WebApplication.CreateBuilder(args);

var keyVaultUri = new Uri("YOUR_KEY_VAULT_URI");
var client = new SecretClient(keyVaultUri, new DefaultAzureCredential());

KeyVaultSecret secret = client.GetSecret("SecretNameForConnectionString");
string connectionString = secret.Value;

builder.Services.AddRazorPages();

var multiplexer = ConnectionMultiplexer.Connect(connectionString);
builder.Services.AddSingleton<IConnectionMultiplexer>(multiplexer);
builder.Services.AddTransient<IProductService, ProductService>();

var app = builder.Build();

if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Error");
    app.UseHsts();
}

app.UseHttpsRedirection();
app.UseStaticFiles();

app.UseRouting();

app.UseAuthorization();

app.MapRazorPages();

app.Run();
