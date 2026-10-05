using Microsoft.Maui.Storage;
using GifScroll.Windows.Services;

namespace GifScroll.Windows.Views;

public partial class AccountPage : ContentPage
{
    private bool _signUpMode;
    private bool _authVisible;

    public AccountPage()
    {
        InitializeComponent();
        Refresh();
    }

    protected override void OnAppearing()
    {
        base.OnAppearing();
        Refresh();
    }

    private void Refresh()
    {
        var client = SupabaseClient.Shared;
        bool signedIn = client.AuthToken != null;
        StatusLabel.Text = signedIn
            ? $"Signed in as {client.DisplayName ?? client.UserId ?? "you"}."
            : "You're browsing anonymously.";
        SignOutButton.IsVisible = signedIn;
        AuthToggleButton.IsVisible = !signedIn;
        SetAuthVisible(_authVisible && !signedIn);
    }

    private void SetAuthVisible(bool visible)
    {
        EmailEntry.IsVisible = visible;
        PasswordEntry.IsVisible = visible;
        NameEntry.IsVisible = visible && _signUpMode;
        PrimaryButton.IsVisible = visible;
        ToggleButton.IsVisible = visible;
        PrimaryButton.Text = _signUpMode ? "Create account" : "Sign in";
        ToggleButton.Text = _signUpMode ? "Sign in instead" : "Create account instead";
    }

    private void OnShowAuthClicked(object? sender, EventArgs e)
    {
        _authVisible = !_authVisible;
        AuthToggleButton.Text = _authVisible ? "Hide" : "Sign in / Sign up";
        SetAuthVisible(_authVisible);
    }

    private void OnToggleClicked(object? sender, EventArgs e)
    {
        _signUpMode = !_signUpMode;
        SetAuthVisible(true);
    }

    private async void OnPrimaryClicked(object? sender, EventArgs e)
    {
        var email = EmailEntry.Text?.Trim();
        var password = PasswordEntry.Text;
        if (string.IsNullOrEmpty(email) || string.IsNullOrEmpty(password))
        {
            await DisplayAlert("Hold on", "Enter an email and password.", "OK");
            return;
        }
        try
        {
            SupabaseClient.AuthResult result;
            if (_signUpMode)
            {
                var name = NameEntry.Text?.Trim();
                if (string.IsNullOrEmpty(name))
                {
                    await DisplayAlert("Hold on", "Pick a display name.", "OK");
                    return;
                }
                result = await SupabaseClient.Shared.SignUpAsync(email, password, name);
                SupabaseClient.Shared.DisplayName = name;
            }
            else
            {
                result = await SupabaseClient.Shared.SignInAsync(email, password);
            }
            SupabaseClient.Shared.AuthToken = result.AccessToken;
            SupabaseClient.Shared.UserId = result.UserId;
            Preferences.Default.Set("gifscroll.authToken", result.AccessToken ?? "");
            _authVisible = false;
            Refresh();
        }
        catch
        {
            await DisplayAlert("Couldn't sign in", "Check your credentials and connection.", "OK");
        }
    }

    private void OnSignOutClicked(object? sender, EventArgs e)
    {
        SupabaseClient.Shared.AuthToken = null;
        SupabaseClient.Shared.UserId = null;
        SupabaseClient.Shared.DisplayName = null;
        Preferences.Default.Remove("gifscroll.authToken");
        Refresh();
    }
}
