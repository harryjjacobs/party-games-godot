using Godot;
using System;
using System.Threading.Tasks;
using SpotifyAPI.Web;
using SpotifyAPI.Web.Auth;
using System.Collections.Generic;
using Image = Godot.Image;
using System.Linq;

public class MusiQTrackPlayer : Godot.Object
{
	[Signal] public delegate void requires_authorization();
	[Signal] public delegate void authorization_succeeded();
	[Signal] public delegate void authorization_failed();
	[Signal] public delegate void requires_device_connection();
	[Signal] public delegate void ready_to_play();

	public bool IsAuthorized { get; private set; } = false;

	private const string CLIENT_ID = "35e4b8f45cac4e6ebd25c503005e847e";
	private const int PLAYBACK_TRANSFER_DELAY = 300;  // ms
	private SpotifyClient _spotifyClient;
	private static EmbedIOAuthServer _authServer;

	public GenericFunctionStateTask Play(String trackId)
	{
		return GenericFunctionStateTask.Create(async () =>
		{
			if (!CheckAuth() || !(await CheckDeviceConnectionAsync())) return false;
			var track = await _spotifyClient.Tracks.Get(trackId);
			return await _spotifyClient.Player.ResumePlayback(new PlayerResumePlaybackRequest()
			{
				Uris = new[] { trackId }
			});
		});
	}

	public FunctionStateTask Stop()
	{
		return new FunctionStateTask(async () =>
		{
			if (!CheckAuth() || !(await CheckDeviceConnectionAsync())) return;
		});
	}

	public GenericFunctionStateTask SearchPlaylistsAndAlbums(string query)
	{
		return GenericFunctionStateTask.Create(async () =>
		{
			if (!CheckAuth()) return new PlaylistAlbumSearch();
			var result = (await _spotifyClient.Search.Item(new SearchRequest(SearchRequest.Types.Album | SearchRequest.Types.Playlist, query)));
			var playlists = result.Playlists.Items.ConvertAll(this.PlaylistConverter) ?? new List<SimplePlaylist>();
			var albums = result.Albums.Items.ConvertAll(this.SimpleAlbumConverter) ?? new List<Album>();
			return new PlaylistAlbumSearch()
			{
				Albums = albums,
				Playlists = playlists,
			};
		});
	}

	public GenericFunctionStateTask GetFeaturedPlaylists()
	{
		return GenericFunctionStateTask.Create(async () =>
		{
			if (!CheckAuth()) return null;
			return (await _spotifyClient.Browse.GetFeaturedPlaylists()).Playlists.Items.ConvertAll(PlaylistConverter);
		});
	}

	public GenericFunctionStateTask GetAvailableDevicesForConnection()
	{
		return GenericFunctionStateTask.Create(async () =>
		{
			if (!CheckAuth()) return new List<Device>();
			return (await _spotifyClient.Player.GetAvailableDevices()).Devices.ConvertAll(DeviceConverter);
		});

	}

	public GenericFunctionStateTask PerformDeviceConnection(string device_id)
	{
		return GenericFunctionStateTask.Create(async () =>
		{
			var success = await _spotifyClient.Player.TransferPlayback(new PlayerTransferPlaybackRequest(new[] { device_id }) { Play = false });
			await Task.Delay(PLAYBACK_TRANSFER_DELAY);
			if (success)
			{
				EmitSignal(nameof(ready_to_play));
			}
			return success;
		});
	}

	public FunctionStateTask PerformAuthorization()
	{
		return new FunctionStateTask(async () =>
		{
			IsAuthorized = false;
			_authServer = new EmbedIOAuthServer(new Uri("http://localhost:5000/callback"), 5000);
			await _authServer.Start();

			_authServer.ImplictGrantReceived += OnImplicitGrantReceived;
			_authServer.ErrorReceived += OnErrorReceived;

			var request = new LoginRequest(_authServer.BaseUri, CLIENT_ID, LoginRequest.ResponseType.Token)
			{
				Scope = new[]{ Scopes.UserLibraryRead, Scopes.UserTopRead, Scopes.PlaylistReadPrivate,
								Scopes.AppRemoteControl, Scopes.UserReadCurrentlyPlaying, Scopes.UserReadPlaybackPosition }
			};

			BrowserUtil.Open(request.ToUri());
		});
	}

	public bool CheckAuth()
	{
		if (!IsAuthorized)
		{
			EmitSignal(nameof(requires_authorization));
			return false;
		}
		return true;
	}

	public GenericFunctionStateTask CheckDeviceConnection()
	{
		return GenericFunctionStateTask.Create(CheckDeviceConnectionAsync);
	}

	private async Task<bool> CheckDeviceConnectionAsync()
	{
		var deviceResponse = await _spotifyClient.Player.GetAvailableDevices();
		foreach (var device in deviceResponse.Devices)
		{
			if (device.IsActive)
			{
				return true;
			}
		}
		EmitSignal(nameof(requires_device_connection));
		return false;
	}

	private async Task OnImplicitGrantReceived(object sender, ImplictGrantResponse response)
	{
		await _authServer.Stop();
		_spotifyClient = new SpotifyClient(response.AccessToken);
		IsAuthorized = true;
		EmitSignal(nameof(authorization_succeeded));
	}

	private async Task OnErrorReceived(object sender, string error, string state)
	{
		Console.WriteLine($"Aborting authorization, error received: {error}");
		IsAuthorized = false;
		await _authServer.Stop();
		EmitSignal(nameof(authorization_failed));
	}

	private Track PlayableItemConverter(IPlayableItem playable)
	{
		var track = new Track();
		if (playable is FullTrack fullTrack)
		{
			track.Id = fullTrack.Id;
			track.Title = fullTrack.Name;
			track.DurationMs = fullTrack.DurationMs;
		}
		else if (playable is FullEpisode fullEpisode)
		{
			track.Id = fullEpisode.Id;
			track.Title = fullEpisode.Name;
		}
		return track;
	}

	private Album SimpleAlbumConverter(SimpleAlbum simpleAlbum)
	{
		return new Album()
		{
			Id = simpleAlbum.Id,
			Title = simpleAlbum.Name,
			Artists = simpleAlbum.Artists.ConvertAll(a => a.Name),
		};
	}

	private Track PlaylistTrackConverter(PlaylistTrack<IPlayableItem> playlistTrack)
	{
		return PlayableItemConverter(playlistTrack.Track);
	}

	private SimplePlaylist PlaylistConverter(SpotifyAPI.Web.SimplePlaylist simplePlaylist)
	{
		var playlist = new SimplePlaylist()
		{
			Id = simplePlaylist.Id,
			Title = simplePlaylist.Name,
			Author = simplePlaylist.Owner.DisplayName
			// Image = simplePlaylist.Images.ConvertAll(ImageConverter).FirstOrDefault(null),
		};

		return playlist;
	}

	private Image ImageConverter(SpotifyAPI.Web.Image spotifyImage)
	{
		var image = new Image()
		{
			Url = spotifyImage.Url,
			Width = spotifyImage.Width,
			Height = spotifyImage.Height,
		};
		return image;
	}

	private Device DeviceConverter(SpotifyAPI.Web.Device spotifyDevice)
	{
		var device = new Device()
		{
			Id = spotifyDevice.Id,
			Name = spotifyDevice.Name,
		};
		return device;
	}

	public class PlaylistAlbumSearch : Godot.Object
	{
		public List<Album> Albums { get; set; } = new List<Album>();
		public List<SimplePlaylist> Playlists { get; set; } = new List<SimplePlaylist>();
	}

	public class Device : Godot.Object
	{
		public string Id { get; set; }
		public string Name { get; set; }
	}

	public class Image : Godot.Object
	{
		public string Url { get; set; }
		public int Width { get; set; }
		public int Height { get; set; }
	}

	public class Track : Godot.Object
	{
		public string Id { get; set; }
		public string Title { get; set; }
		public string Artist { get; set; }
		public int DurationMs { get; set; }
	}

	public class Album : Godot.Object
	{
		public string Id { get; set; }
		public string Title { get; set; }
		public List<string> Artists { get; set; } = new List<string>();
	}

	public class SimplePlaylist : Godot.Object
	{
		public string Id { get; set; }
		public string Title { get; set; }
		public string Author { get; set; }
		public Image Image { get; set; }
	}
}
