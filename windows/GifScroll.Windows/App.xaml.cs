using GifScroll.Windows.Services;
using GifScroll.Windows.Views;
using Microsoft.Maui.Storage;

namespace GifScroll.Windows;

public partial class App : Application
{
    public App()
    {
        InitializeComponent();
        // Restore the saved session (if any).
        var token = Preferences.Default.Get("gifscroll.authToken", "");
        if (!string.IsNullOrEmpty(token))
            SupabaseClient.Shared.AuthToken = token;
        MainPage = new AppShell();
    }
}
