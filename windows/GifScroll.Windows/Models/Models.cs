namespace GifScroll.Windows.Models;

public enum FeedItemKind { Image, Gif, Video }

/// <summary>One item in the meme feed: a captioned image, GIF, or video.</summary>
public sealed class FeedItem
{
    public FeedItem(string id, string title, FeedItemKind kind, string url)
    { Id = id; Title = title; Kind = kind; Url = url; }

    public string Id { get; }
    public string Title { get; }
    public FeedItemKind Kind { get; }
    public string Url { get; }

    public bool IsVideo => Kind == FeedItemKind.Video;
    public bool IsNotVideo => !IsVideo;
    public bool Liked { get; set; }
}

public sealed class Comment
{
    public string Id { get; set; } = "";
    public string Author { get; set; } = "anon";
    public string Body { get; set; } = "";
    public DateTime CreatedAt { get; set; }
}

public sealed class Post
{
    public string Id { get; set; } = "";
    public string Title { get; set; } = "";
    public string MediaUrl { get; set; } = "";
    public string Author { get; set; } = "";
    public int Laughs { get; set; }
}
