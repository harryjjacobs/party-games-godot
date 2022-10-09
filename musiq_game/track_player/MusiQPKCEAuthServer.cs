using System;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using EmbedIO;
using EmbedIO.Actions;
using SpotifyAPI.Web;
using SpotifyAPI.Web.Auth;

class MusiQPKCEAuthServer : IAuthServer
{
  private System.Uri uri;
  private string verifier;

  private CancellationTokenSource _cancelTokenSource;
  private readonly WebServer _webServer;

  public event Func<object, AuthorizationCodeResponse, Task> AuthorizationCodeReceived;
  public event Func<object, ImplictGrantResponse, Task> ImplictGrantReceived;

  public Uri BaseUri => throw new NotImplementedException();

  public event Func<PKCETokenResponse, Task> PKCEGrantReceived;
  public event Func<string, string, Task> ErrorReceived;

  public MusiQPKCEAuthServer(string clientId, System.Uri uri, string verifier)
  {
    this.uri = uri;
    this.verifier = verifier;

    _webServer = new WebServer(uri.Port)
      .WithModule(new ActionModule("/", HttpVerbs.Any, (ctx) =>
      {
        var query = ctx.Request.QueryString;
        var error = query["error"];
        if (error != null)
        {
          ErrorReceived?.Invoke(error, query["state"]);
          return ctx.SendStringAsync("Log in failed. You can close this tab now", "text/plain", Encoding.UTF8);
        }

        var code = query.Get("code");
        if (code != null)
        {
          new OAuthClient().RequestToken(
            new PKCETokenRequest(clientId, code, uri, verifier)
            ).ContinueWith((task) => PKCEGrantReceived?.Invoke(task.Result));
        }

        return ctx.SendStringAsync("Log in completed. You can close this tab now", "text/plain", Encoding.UTF8);
      }));
  }

  public Task Start()
  {
    _cancelTokenSource = new CancellationTokenSource();
    _webServer.Start(_cancelTokenSource.Token);
    return Task.CompletedTask;
  }

  public Task Stop()
  {
    _cancelTokenSource?.Cancel();
    return Task.CompletedTask;
  }

  public void Dispose()
  {
    Dispose(true);
    GC.SuppressFinalize(this);
  }

  protected virtual void Dispose(bool disposing)
  {
    if (disposing)
    {
      _webServer?.Dispose();
    }
  }
}