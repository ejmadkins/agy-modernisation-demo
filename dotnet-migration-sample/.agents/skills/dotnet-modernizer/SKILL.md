# Skill: .NET Modernization Specialist

This skill packages senior-level expertise for modernizing .NET Framework and older .NET Core (e.g. .NET 5) applications to modern .NET 8.0, migrating from Entity Framework 6 (SQL Server) to Entity Framework Core (PostgreSQL), and adding Google Cloud Run serverless contract compliance.

---

## 1. Project Upgrade (`.csproj`)

When modernizing the `.csproj`, target `net8.0`, use modern SDK `Microsoft.NET.Sdk.Web`, remove legacy `EntityFramework` packages, and replace with modern EF Core PostgreSQL libraries:

```xml
<Project Sdk="Microsoft.NET.Sdk.Web">
  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
    <Nullable>enable</Nullable>
    <ImplicitUsings>enable</ImplicitUsings>
  </PropertyGroup>

  <ItemGroup>
    <PackageReference Include="Npgsql.EntityFrameworkCore.PostgreSQL" Version="8.0.0" />
    <PackageReference Include="Microsoft.EntityFrameworkCore.Tools" Version="8.0.0">
      <PrivateAssets>all</PrivateAssets>
      <IncludeAssets>runtime; build; native; contentfiles; analyzers; buildtransitive</IncludeAssets>
    </PackageReference>
    <PackageReference Include="Microsoft.AspNetCore.Mvc.NewtonsoftJson" Version="8.0.0" />
    <PackageReference Include="PagedList.Core.Mvc" Version="3.0.0" />
    <PackageReference Include="System.Configuration.ConfigurationManager" Version="8.0.0" />
  </ItemGroup>
</Project>
```

---

## 2. Entity Framework Core & PostgreSQL Refactoring

### Pluralization and Explicit Table Mapping
EF6 had conventions that implicitly pluralized or mapped tables. In EF Core, you must map entity tables explicitly in `OnModelCreating` to ensure they map to singular names if that's what the legacy schema uses:

```csharp
protected override void OnModelCreating(ModelBuilder modelBuilder)
{
    modelBuilder.Entity<Course>().ToTable("Course");
    modelBuilder.Entity<Department>().ToTable("Department");
    modelBuilder.Entity<Enrollment>().ToTable("Enrollment");
    modelBuilder.Entity<Instructor>().ToTable("Instructor");
    modelBuilder.Entity<OfficeAssignment>().ToTable("OfficeAssignment");
    modelBuilder.Entity<Student>().ToTable("Student");
    modelBuilder.Entity<Person>().ToTable("Person");
}
```

### PostgreSQL RowVersion Concurrency Handling
SQL Server uses `byte[]` with `[Timestamp]` (RowVersion) columns for optimistic concurrency. PostgreSQL does not have a binary RowVersion column, but it has a built-in system column named `xmin` (representing the transaction ID of the last modification) which works perfectly as a concurrency token.

Map legacy `RowVersion` properties to `xmin` in `OnModelCreating`:

```csharp
modelBuilder.Entity<Department>()
    .Property(d => d.RowVersion)
    .IsRowVersion()
    .UseXminAsConcurrencyToken();
```

### DbInitializer & Seeding
In EF Core, replace legacy initializers (e.g. `DropCreateDatabaseIfModelChanges`) with standard initialization logic inside a `DbInitializer` class called at application startup:

```csharp
public static class DbInitializer
{
    public static void Initialize(SchoolContext context)
    {
        context.Database.EnsureCreated(); // Creates database and tables if they don't exist

        if (context.Students.Any())
        {
            return;   // DB has been seeded
        }

        // Add seed data
        var students = new Student[] { ... };
        context.Students.AddRange(students);
        context.SaveChanges();
    }
}
```

---

## 3. Dependency Injection & Program.cs

Consolidate `Startup.cs` configuration and registrations directly into the unified `Program.cs` file. Register Kestrel, controllers, and the PostgreSQL DbContext:

```csharp
using Microsoft.EntityFrameworkCore;
using ContosoUniversity.DAL;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddControllersWithViews()
    .AddNewtonsoftJson();

builder.Services.AddDbContext<SchoolContext>(options =>
    options.UseNpgsql(builder.Configuration.GetConnectionString("SchoolContext")));

var app = builder.Build();

// Database initialization
using (var scope = app.Services.CreateScope())
{
    var services = scope.ServiceProvider;
    try
    {
        var context = services.GetRequiredService<SchoolContext>();
        DbInitializer.Initialize(context);
    }
    catch (Exception ex)
    {
        var logger = services.GetRequiredService<ILogger<Program>>();
        logger.LogError(ex, "An error occurred creating/seeding the database.");
    }
}

// Middleware pipeline...
app.UseStaticFiles();
app.UseRouting();
app.MapControllerRoute(
    name: "default",
    pattern: "{controller=Home}/{action=Index}/{id?}");

app.Run();
```

---

## 4. Google Cloud Run Compliance

### Port Binding
Google Cloud Run injects a `PORT` environment variable. The application must listen on `0.0.0.0` on that exact port:

```csharp
var port = Environment.GetEnvironmentVariable("PORT") ?? "8080";
builder.WebHost.ConfigureKestrel(options =>
{
    options.ListenAnyIP(int.Parse(port));
});
```

### Structured Console JSON Logging
GCP Cloud Logging parses structured JSON outputs written to console. Configure standard logging to output JSON Console records:

```csharp
builder.Logging.ClearProviders();
builder.Logging.AddJsonConsole(options =>
{
    options.IncludeScopes = true;
    options.TimestampFormat = "yyyy-MM-ddTHH:mm:ss.ffffffZ ";
    options.UseUtcTimestamp = true;
});
```

### Graceful Shutdown (SIGTERM Handling)
Hook into application lifetime events to catch SIGTERM and shutdown cleanly:

```csharp
app.Lifetime.ApplicationStopping.Register(() =>
{
    Console.WriteLine("SIGTERM received. Cleaning up connections...");
    // Perform any custom cleanups here
});
```
