using System.Text.Json;
using System.Text.Json.Serialization;
using GifScroll.Windows.Models;

namespace GifScroll.Windows.Services;

// MARK: - Reddit JSON

file sealed class RedditListing
{
    [JsonPropertyName("data")] public RedditListingData Data { get; set; } = new();
}
file sealed class RedditListingData
{
    [JsonPropertyName("children")] public List<RedditChild> Children { get; set; } = new();
}
file sealed class RedditChild
{
    [JsonPropertyName("data")] public RedditPost Data { get; set; } = new();
}
file sealed class RedditPost
{
    [JsonPropertyName("id")] public string Id { get; set; } = "";
    [JsonPropertyName("title")] public string Title { get; set; } = "";
    [JsonPropertyName("url")] public string? Url { get; set; }
    [JsonPropertyName("post_hint")] public string? PostHint { get; set; }
    [JsonPropertyName("is_video")] public bool? IsVideo { get; set; }
    [JsonPropertyName("over_18")] public bool? Over18 { get; set; }
    [JsonPropertyName("stickied")] public bool? Stickied { get; set; }
    [JsonPropertyName("media")] public RedditMedia? Media { get; set; }
}
file sealed class RedditMedia
{
    [JsonPropertyName("reddit_video")] public RedditVideo? RedditVideo { get; set; }
}
file sealed class RedditVideo
{
    [JsonPropertyName("fallback_url")] public string? FallbackUrl { get; set; }
}

/// <summary>
/// The main feed: funny memes, GIFs, and videos from Reddit's meme
/// communities. Free, no API key — Reddit's public JSON endpoints.
/// </summary>
public sealed class RedditService
{
    private static readonly string[] Subreddits = { "memes", "dankmemes", "funny" };
    private static readonly HttpClient Http = new();
    private readonly Random _rng = new();

    public LikeManager? LikeManager { get; set; }

    public bool IsLoading { get; private set; }
    public string? ErrorMessage { get; private set; }

    public event Action? Changed;

    public async Task<List<FeedItem>> MemeFeedAsync(CancellationToken ct = default)
    {
        IsLoading = true;
        ErrorMessage = null;
        Changed?.Invoke();
        try
        {
            string sub = Subreddits[_rng.Next(Subreddits.Length)];
            var url = $"https://www.reddit.com/r/{sub}/hot.json?limit=50";
            using var req = new HttpRequestMessage(HttpMethod.Get, url);
            req.Headers.UserAgent.ParseAdd("GifScroll/1.0 (by /u/gifscroll)");
            using var resp = await Http.SendAsync(req, ct);
            resp.EnsureSuccessStatusCode();
            var json = await resp.Content.ReadAsStringAsync(ct);
            var listing = JsonSerializer.Deserialize<RedditListing>(json);
            var items = listing?.Data.Children
                .Select(c => FromReddit(c.Data))
                .Where(i => i != null)
                .Cast<FeedItem>()
                .ToList() ?? new();

            if (LikeManager != null)
                items.Sort((a, b) => LikeManager.Score(b.Id, b.Title)
                    .CompareTo(LikeManager.Score(a.Id, a.Title)));

            return items;
        }
        catch (OperationCanceledException) { return new(); }
        catch
        {
            ErrorMessage = "Couldn't load memes. Check your connection.";
            return new();
        }
        finally
        {
            IsLoading = false;
            Changed?.Invoke();
        }
    }

    private static FeedItem? FromReddit(RedditPost post)
    {
        if (post.Over18 == true || post.Stickied == true) return null;
        var title = (post.Title ?? "").Trim();
        if (string.IsNullOrEmpty(title) || title == "[deleted]" || title == "[removed]") return null;

        if (post.IsVideo == true && post.Media?.RedditVideo?.FallbackUrl is string raw)
        {
            var vurl = raw.Replace("&amp;", "&").Replace("&lt;", "<").Replace("&gt;", ">").Replace("&quot;", "\"");
            return new FeedItem(post.Id, title, FeedItemKind.Video, vurl);
        }

        if (post.Url is not string url || !Uri.TryCreate(url, UriKind.Absolute, out var uri))
            return null;
        var ext = Path.GetExtension(uri.AbsolutePath).TrimStart('.').ToLowerInvariant();
        return ext switch
        {
            "gif" => new FeedItem(post.Id, title, FeedItemKind.Gif, url),
            "jpg" or "jpeg" or "png" => new FeedItem(post.Id, title, FeedItemKind.Image, url),
            _ => null,
        };
    }
}
