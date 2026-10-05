using System.Collections.ObjectModel;
using System.ComponentModel;
using System.Runtime.CompilerServices;
using GifScroll.Windows.Models;
using GifScroll.Windows.Services;

namespace GifScroll.Windows.Views;

public partial class FeedPage : ContentPage, INotifyPropertyChanged
{
    private readonly RedditService _reddit = new();
    private readonly LikeManager _likes = new();

    public ObservableCollection<FeedItem> Items { get; } = new();

    private bool _isLoading;
    public bool IsLoading
    {
        get => _isLoading;
        set { _isLoading = value; OnPropertyChanged(); }
    }

    private string? _errorMessage;
    public string? ErrorMessage
    {
        get => _errorMessage;
        set { _errorMessage = value; OnPropertyChanged(); OnPropertyChanged(nameof(HasError)); }
    }
    public bool HasError => !string.IsNullOrEmpty(ErrorMessage);

    public new event PropertyChangedEventHandler? PropertyChanged;
    protected void OnPropertyChanged([CallerMemberName] string? name = null)
        => PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(name));

    public FeedPage()
    {
        InitializeComponent();
        BindingContext = this;
        _reddit.LikeManager = _likes;
        _likes.Changed += () =>
        {
            foreach (var item in Items)
                item.Liked = _likes.IsLiked(item.Id);
        };
    }

    protected override void OnAppearing()
    {
        base.OnAppearing();
        if (Items.Count == 0)
            _ = LoadAsync();
    }

    private async Task LoadAsync()
    {
        IsLoading = true;
        ErrorMessage = null;
        var items = await _reddit.MemeFeedAsync();
        Items.Clear();
        foreach (var item in items)
        {
            item.Liked = _likes.IsLiked(item.Id);
            Items.Add(item);
        }
        ErrorMessage = _reddit.ErrorMessage;
        IsLoading = false;
    }

    private void OnLikeClicked(object? sender, EventArgs e)
    {
        if (sender is Button b && b.CommandParameter is FeedItem item)
        {
            _likes.ToggleLike(item.Id, item.Title);
            item.Liked = _likes.IsLiked(item.Id);
            b.Text = item.Liked ? "🤣" : "😂";
        }
    }

    private async void OnCommentsClicked(object? sender, EventArgs e)
    {
        if (sender is Button b && b.CommandParameter is FeedItem item)
            await Navigation.PushAsync(new CommentsPage(gifId: item.Id, title: item.Title));
    }

    private async void OnReportClicked(object? sender, EventArgs e)
    {
        if (sender is Button b && b.CommandParameter is FeedItem item)
        {
            string? reason = await DisplayActionSheet("Report this meme", "Cancel", null,
                "Spam", "Harassment", "NSFW", "Copyright", "Other");
            if (reason == null || reason == "Cancel") return;
            try
            {
                await SupabaseClient.Shared.ReportAsync(reason, "", "windows-user", gifId: item.Id);
                await DisplayAlert("Reported", "Thanks — we'll take a look.", "OK");
            }
            catch
            {
                await DisplayAlert("Couldn't report", "Check your connection and try again.", "OK");
            }
        }
    }
}
