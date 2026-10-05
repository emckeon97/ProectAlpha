using System.Collections.ObjectModel;
using GifScroll.Windows.Models;
using GifScroll.Windows.Services;

namespace GifScroll.Windows.Views;

public partial class CommentsPage : ContentPage
{
    private readonly string? _gifId;
    private readonly string? _postId;
    private readonly ObservableCollection<Comment> _comments = new();

    public CommentsPage(string? gifId = null, string? postId = null, string? title = null)
    {
        InitializeComponent();
        _gifId = gifId;
        _postId = postId;
        TitleLabel.Text = title ?? "Comments";
        CommentsList.ItemsSource = _comments;
    }

    protected override void OnAppearing()
    {
        base.OnAppearing();
        _ = LoadAsync();
    }

    private async Task LoadAsync()
    {
        try
        {
            var list = await SupabaseClient.Shared.FetchCommentsAsync(_postId, _gifId);
            _comments.Clear();
            foreach (var c in list) _comments.Add(c);
        }
        catch
        {
            // Offline — empty view covers it.
        }
    }

    private async void OnSendClicked(object? sender, EventArgs e)
    {
        var body = CommentEntry.Text?.Trim();
        if (string.IsNullOrEmpty(body)) return;
        CommentEntry.Text = "";
        try
        {
            await SupabaseClient.Shared.PostCommentAsync(body, "windows-user", _postId, _gifId);
            await LoadAsync();
        }
        catch
        {
            await DisplayAlert("Couldn't post", "Check your connection and try again.", "OK");
        }
    }
}
