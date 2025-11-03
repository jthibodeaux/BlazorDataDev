using Microsoft.AspNetCore.Authentication;
using System.Security.Claims;

namespace BlazorDbEditor.Services;

/// <summary>
/// Custom claims transformation that adds role claims based on user email mapping in appsettings.json
/// </summary>
public class RoleClaimsTransformation : IClaimsTransformation
{
    private readonly IConfiguration _configuration;
    private readonly ILogger<RoleClaimsTransformation> _logger;

    public RoleClaimsTransformation(IConfiguration configuration, ILogger<RoleClaimsTransformation> logger)
    {
        _configuration = configuration;
        _logger = logger;
    }

    public Task<ClaimsPrincipal> TransformAsync(ClaimsPrincipal principal)
    {
        // Create a clone of the principal to add claims
        var clone = principal.Clone();
        var identity = (ClaimsIdentity?)clone.Identity;

        if (identity == null || !identity.IsAuthenticated)
        {
            return Task.FromResult(principal);
        }

        // Get user email from Windows identity
        // Try multiple claim types that might contain the email
        var email = GetUserEmail(identity);

        if (string.IsNullOrEmpty(email))
        {
            _logger.LogWarning("Could not extract email from user identity. Available claims: {Claims}",
                string.Join(", ", identity.Claims.Select(c => $"{c.Type}={c.Value}")));
            return Task.FromResult(principal);
        }

        _logger.LogInformation("Processing role claims for user: {Email}", email);

        // Get user roles from appsettings
        var userRoles = _configuration.GetSection($"Authorization:UserRoles:{email}").Get<List<string>>();

        if (userRoles != null && userRoles.Any())
        {
            foreach (var role in userRoles)
            {
                // Add role claim if it doesn't already exist
                if (!identity.HasClaim(ClaimTypes.Role, role))
                {
                    identity.AddClaim(new Claim(ClaimTypes.Role, role));
                    _logger.LogInformation("Added role '{Role}' to user {Email}", role, email);
                }
            }
        }
        else
        {
            _logger.LogWarning("No roles found for user: {Email}", email);
            
            // Add default "LoggedIn" role for authenticated users without specific roles
            if (!identity.HasClaim(ClaimTypes.Role, "LoggedIn"))
            {
                identity.AddClaim(new Claim(ClaimTypes.Role, "LoggedIn"));
                _logger.LogInformation("Added default 'LoggedIn' role to user {Email}", email);
            }
        }

        return Task.FromResult(clone);
    }

    private string? GetUserEmail(ClaimsIdentity identity)
    {
        // Try to get email from various claim types
        var email = identity.FindFirst(ClaimTypes.Email)?.Value
                    ?? identity.FindFirst(ClaimTypes.Upn)?.Value  // User Principal Name
                    ?? identity.FindFirst(ClaimTypes.Name)?.Value; // Fallback to Name

        // If the name looks like a Windows domain account (DOMAIN\username), try to extract email
        if (!string.IsNullOrEmpty(email) && email.Contains("\\"))
        {
            var username = email.Split('\\').Last();
            // Check if we have a mapping for the username
            var mappedEmail = _configuration.GetSection($"Authorization:UserRoles")
                .GetChildren()
                .Select(c => c.Key)
                .FirstOrDefault(key => key.Equals(username, StringComparison.OrdinalIgnoreCase) 
                                    || key.StartsWith(username + "@", StringComparison.OrdinalIgnoreCase));
            
            if (!string.IsNullOrEmpty(mappedEmail))
            {
                return mappedEmail;
            }
        }

        return email;
    }
}
