using System.Text;
using System.Text.Json;
using GifScroll.Windows.Models;

namespace GifScroll.Windows.Services;

/// <summary>
/// Thin REST client for Supabase — no SDK dependency.
/// Uses the project's publishable key, which is designed to ship in clients
/// (same key the iOS/Android apps ship with).
/// </summary>
public sealed class SupabaseClient
{
    public static SupabaseClient Shared { get; } = new();

    private const string ProjectUrl = "https://btfbjmdtnjntqkybpqrk.supabase.co";
    private const string ApiKey = "sb_publishable_NM4BBwTL1kRxlAjnNkGW9g_U0q-VDCF";

    private static readonly HttpClient Http = new();

    /// <summary>Set after sign-in; used as the Bearer token instead of the key.</summary>
    public string? AuthToken { get; set; }
    public string? UserId { get; set; }
    public string? DisplayName { get; set; }

    private string Bearer => AuthToken ?? ApiKey;

    private SupabaseClient() { }

    private HttpRequestMessage Request(HttpMethod method, string path, string? query = null)
    {
        var req = new HttpRequestMessage(method, ProjectUrl + path + (query != null ? "?" + query : ""));
        req.Headers.Add("apikey", ApiKey);
        req.Headers.Authorization = new("Bearer", Bearer);
        return req;
    }

    // MARK: - Auth

    public record AuthResult(string? AccessToken, string? UserId, string? Email);

    public async Task<AuthResult> SignUpAsync(string email, string password, string displayName)
    {
        using var req = Request(HttpMethod.Post, "/auth/v1/signup");
        req.Content = JsonContent(new { email, password, data = new { display_name = displayName } });
        using var resp = await Http.SendAsync(req);
        resp.EnsureSuccessStatusCode();
        return ParseAuth(await resp.Content.ReadAsStringAsync());
    }

    public async Task<AuthResult> SignInAsync(string email, string password)
    {
        using var req = Request(HttpMethod.Post, "/auth/v1/token", "grant_type=password");
        req.Content = JsonContent(new { email, password });
        using var resp = await Http.SendAsync(req);
        resp.EnsureSuccessStatusCode();
        return ParseAuth(await resp.Content.ReadAsStringAsync());
    }

    private static AuthResult ParseAuth(string json)
    {
        using var doc = JsonDocument.Parse(json);
        var root = doc.RootElement;
        string? token = root.TryGetProperty("access_token", out var t) ? t.GetString() : null;
        string? uid = null, email = null;
        if (root.TryGetProperty("user", out var u))
        {
            uid = u.TryGetProperty("id", out var i) ? i.GetString() : null;
            email = u.TryGetProperty("email", out var e) ? e.GetString() : null;
        }
        return new AuthResult(token, uid, email);
    }

    // MARK: - Comments

    public async Task<List<Comment>> FetchCommentsAsync(string? postId = null, string? gifId = null)
    {
        var q = "select=*&order=created_at.asc";
        if (postId != null) q += $"&post_id=eq.{Uri.EscapeDataString(postId)}";
        else if (gifId != null) q += $"&gif_id=eq.{Uri.EscapeDataString(gifId)}";
        using var req = Request(HttpMethod.Get, "/rest/v1/comments", q);
        using var resp = await Http.SendAsync(req);
        resp.EnsureSuccessStatusCode();
        var list = new List<Comment>();
        using var doc = JsonDocument.Parse(await resp.Content.ReadAsStringAsync());
        foreach (var el in doc.RootElement.EnumerateArray())
        {
            list.Add(new Comment
            {
                Id = el.GetProperty("id").GetString() ?? "",
                Author = el.TryGetProperty("display_name", out var a) ? a.GetString() ?? "anon" : "anon",
                Body = el.TryGetProperty("body", out var b) ? b.GetString() ?? "" : "",
                CreatedAt = el.TryGetProperty("created_at", out var c) && c.TryGetDateTime(out var dt) ? dt : DateTime.MinValue,
            });
        }
        return list;
    }

    public async Task PostCommentAsync(string body, string displayName, string? postId = null, string? gifId = null)
    {
        using var req = Request(HttpMethod.Post, "/rest/v1/comments");
        var payload = new Dictionary<string, object?> { ["body"] = body, ["display_name"] = displayName };
        if (postId != null) payload["post_id"] = postId;
        if (gifId != null) payload["gif_id"] = gifId;
        req.Content = JsonContent(payload);
        req.Headers.Add("Prefer", "return=representation");
        using var resp = await Http.SendAsync(req);
        resp.EnsureSuccessStatusCode();
    }

    // MARK: - Reports

    public async Task ReportAsync(string reason, string details, string reporterName, string? gifId = null, string? postId = null)
    {
        using var req = Request(HttpMethod.Post, "/rest/v1/reports");
        var payload = new Dictionary<string, object?>
        {
            ["reason"] = reason, ["details"] = details, ["reporter_name"] = reporterName,
        };
        if (gifId != null) payload["gif_id"] = gifId;
        if (postId != null) payload["post_id"] = postId;
        req.Content = JsonContent(payload);
        using var resp = await Http.SendAsync(req);
        resp.EnsureSuccessStatusCode();
    }

    // MARK: - Posts (user uploads feed)

    public async Task<List<Post>> FetchPostsAsync()
    {
        using var req = Request(HttpMethod.Get, "/rest/v1/posts", "select=*&order=created_at.desc&limit=100");
        using var resp = await Http.SendAsync(req);
        resp.EnsureSuccessStatusCode();
        var list = new List<Post>();
        using var doc = JsonDocument.Parse(await resp.Content.ReadAsStringAsync());
        foreach (var el in doc.RootElement.EnumerateArray())
        {
            list.Add(new Post
            {
                Id = el.GetProperty("id").GetString() ?? "",
                Title = el.TryGetProperty("caption", out var c) ? c.GetString() ?? "" : "",
                MediaUrl = el.TryGetProperty("image_url", out var u) ? u.GetString() ?? "" : "",
                Author = el.TryGetProperty("display_name", out var a) ? a.GetString() ?? "anon" : "anon",
            });
        }
        return list;
    }

    private static StringContent JsonContent(object payload)
        => new(JsonSerializer.Serialize(payload), Encoding.UTF8, "application/json");
}
