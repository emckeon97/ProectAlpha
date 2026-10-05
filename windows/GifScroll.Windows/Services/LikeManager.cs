using System.Text.Json;
using Microsoft.Maui.Storage;

namespace GifScroll.Windows.Services;

/// <summary>
/// Local-only like store + content-based ranking.
/// Learns keywords from the titles of memes you like, then scores new
/// memes by how closely their titles match. Likes persist across launches.
/// </summary>
public sealed class LikeManager
{
    private static readonly HashSet<string> Stopwords = new(StringComparer.OrdinalIgnoreCase)
    {
        "the", "a", "an", "and", "or", "of", "to", "in", "on", "for",
        "with", "gif", "giphy", "via", "from", "this", "that", "you"
    };

    private const string LikedKey = "gifscroll.likedIDs";
    private const string KeywordsKey = "gifscroll.keywordScores";

    private readonly HashSet<string> _likedIDs = new();
    private readonly Dictionary<string, double> _keywordScores = new();

    public event Action? Changed;

    public LikeManager()
    {
        var likedJson = Preferences.Default.Get(LikedKey, "[]");
        try
        {
            foreach (var id in JsonSerializer.Deserialize<List<string>>(likedJson) ?? new())
                _likedIDs.Add(id);
        }
        catch { }
        var kwJson = Preferences.Default.Get(KeywordsKey, "{}");
        try
        {
            foreach (var kv in JsonSerializer.Deserialize<Dictionary<string, double>>(kwJson) ?? new())
                _keywordScores[kv.Key] = kv.Value;
        }
        catch { }
    }

    public bool IsLiked(string id) => _likedIDs.Contains(id);
    public int LikedCount => _likedIDs.Count;

    public void ToggleLike(string id, string title)
    {
        if (_likedIDs.Contains(id))
        {
            _likedIDs.Remove(id);
            AdjustKeywords(title, -1);
        }
        else
        {
            _likedIDs.Add(id);
            AdjustKeywords(title, 1);
        }
        Save();
        Changed?.Invoke();
    }

    /// <summary>How strongly an item matches your liked keywords. Higher = show first.</summary>
    public double Score(string id, string title)
        => Keywords(title).Sum(w => _keywordScores.TryGetValue(w, out var s) ? s : 0);

    private void AdjustKeywords(string title, double amount)
    {
        foreach (var w in Keywords(title))
            _keywordScores[w] = _keywordScores.TryGetValue(w, out var s) ? s + amount : amount;
        foreach (var k in _keywordScores.Where(kv => kv.Value == 0).Select(kv => kv.Key).ToList())
            _keywordScores.Remove(k);
    }

    private static IEnumerable<string> Keywords(string title)
    {
        var sb = new System.Text.StringBuilder(title.Length);
        foreach (char ch in title.ToLowerInvariant())
            sb.Append(char.IsLetterOrDigit(ch) ? ch : ' ');
        return sb.ToString().Split(' ', StringSplitOptions.RemoveEmptyEntries)
            .Where(w => w.Length > 2 && !Stopwords.Contains(w));
    }

    private void Save()
    {
        Preferences.Default.Set(LikedKey, JsonSerializer.Serialize(_likedIDs.ToList()));
        Preferences.Default.Set(KeywordsKey, JsonSerializer.Serialize(_keywordScores));
    }
}
