using System.Collections.ObjectModel;
using GifScroll.Windows.Models;
using GifScroll.Windows.Services;

namespace GifScroll.Windows.Views;

public partial class UploadsPage : ContentPage
{
    private readonly ObservableCollection<Post> _posts = new();

    public UploadsPage()
    {
        InitializeComponent();
        PostsList.ItemsSource = _posts;
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
            var list = await SupabaseClient.Shared.FetchPostsAsync();
            _posts.Clear();
            foreach (var p in list) _posts.Add(p);
        }
        catch
        {
            // Offline — empty view covers it.
        }
    }

    private async void OnCommentsClicked(object? sender, EventArgs e)
    {
        if (sender is Button b && b.CommandParameter is Post post)
            await Navigation.PushAsync(new CommentsPage(postId: post.Id, title: post.Title));
    }
}
