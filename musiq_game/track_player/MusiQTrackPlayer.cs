using Godot;
using System;
using System.Threading.Tasks;
using SpotifyAPI.Web;
using SpotifyAPI.Web.Auth;
using System.Collections.Generic;
// using Image = Godot.Image;

public class MusiQTrackPlayer : Godot.Object
{
	[Signal] public delegate void requires_authorization();
	[Signal] public delegate void authorization_succeeded();
	[Signal] public delegate void authorization_failed();
	[Signal] public delegate void requires_device_connection();
	[Signal] public delegate void ready_to_play();

	public bool IsAuthorized { get; private set; } = false;

	public string CurrentAccessToken { get; private set; }

	private const string CLIENT_ID = "35e4b8f45cac4e6ebd25c503005e847e";
	private const int PLAYBACK_TRANSFER_DELAY = 300;  // ms
	private SpotifyClient _spotifyClient;
	private static EmbedIOAuthServer _authServer;

	public GenericFunctionStateTask Play(String trackId)
	{
		return GenericFunctionStateTask.Create(async () =>
		{
			if (!CheckAuth() || !(await CheckDeviceConnectionAsync())) return false;

			try
			{
				var track = await _spotifyClient.Tracks.Get(trackId);

				return await _spotifyClient.Player.ResumePlayback(new PlayerResumePlaybackRequest()
				{
					Uris = new[] { track.Uri }
				});
			}
			catch (APIException e)
			{
				GD.Print(e.ToString());
				return false;
			}
		});
	}

	public GenericFunctionStateTask Resume()
	{
		return GenericFunctionStateTask.Create(async () =>
		{
			if (!CheckAuth() || !(await CheckDeviceConnectionAsync())) return false;

			try
			{
				return await _spotifyClient.Player.ResumePlayback();
			}
			catch (APIException e)
			{
				GD.Print(e.ToString());
				return false;
			}
		});
	}

	public GenericFunctionStateTask Pause()
	{
		return GenericFunctionStateTask.Create(async () =>
		{
			if (!CheckAuth() || !(await CheckDeviceConnectionAsync())) return false;

			return await _spotifyClient.Player.PausePlayback();
		});
	}

	public GenericFunctionStateTask GetTrack(string trackId)
	{
		return GenericFunctionStateTask.Create(async () =>
		{
			if (!CheckAuth() || !(await CheckDeviceConnectionAsync())) return new Track();

			return PlayableItemConverter(await _spotifyClient.Tracks.Get(trackId));
		});
	}

	public GenericFunctionStateTask SearchPlaylistsAndAlbums(string query)
	{
		return GenericFunctionStateTask.Create(async () =>
		{
			if (!CheckAuth()) return new PlayableItemCollectionSearch();
			var result = (await _spotifyClient.Search.Item(new SearchRequest(SearchRequest.Types.Album | SearchRequest.Types.Playlist, query)));
			var playlists = result.Playlists.Items.ConvertAll(PlaylistConverter) ?? new List<SimplePlaylist>();
			var albums = result.Albums.Items.ConvertAll(SimpleAlbumConverter) ?? new List<SimpleAlbum>();
			return new PlayableItemCollectionSearch()
			{
				Albums = albums,
				Playlists = playlists,
			};
		});
	}

	public GenericFunctionStateTask FetchPlayableItemCollectionTracks(PlayableItemCollection collection)
	{
		return GenericFunctionStateTask.Create(async () =>
		{
			List<Track> tracks = new List<Track>();
			if (!CheckAuth()) return tracks;

			if (collection is SimplePlaylist)
			{
				var paginatedPlaylistTracks = await _spotifyClient.Playlists.GetItems(collection.Id);
				var spotifyTrackList = new List<SpotifyAPI.Web.PlaylistTrack<SpotifyAPI.Web.IPlayableItem>>(await _spotifyClient.PaginateAll(paginatedPlaylistTracks));
				tracks = spotifyTrackList.ConvertAll(PlaylistTrackConverter);
			}
			else if (collection is SimpleAlbum)
			{
				var paginatedTracks = await _spotifyClient.Albums.GetTracks(collection.Id);
				var spotifyTrackList = new List<SpotifyAPI.Web.SimpleTrack>(await _spotifyClient.PaginateAll(paginatedTracks));
				tracks = spotifyTrackList.ConvertAll(SimpleTrackConverter);
			}
			return tracks;
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
			var devices = (await _spotifyClient.Player.GetAvailableDevices()).Devices;
			if (devices == null) return new List<Device>();
			return devices.ConvertAll(DeviceConverter);
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
				CallDeferred("emit_signal", nameof(ready_to_play));
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
		CallDeferred("emit_signal", nameof(requires_device_connection));
		return false;
	}

	private async Task OnImplicitGrantReceived(object sender, ImplictGrantResponse response)
	{
		await _authServer.Stop();
		CurrentAccessToken = response.AccessToken;
		_spotifyClient = new SpotifyClient(CurrentAccessToken);
		IsAuthorized = true;
		CallDeferred("emit_signal", nameof(authorization_succeeded));
		await CheckDeviceConnectionAsync().ContinueWith((task) =>
		{
			if (task.Result)
			{
				CallDeferred("emit_signal", nameof(ready_to_play));
			}
		});
	}

	private async Task OnErrorReceived(object sender, string error, string state)
	{
		Console.WriteLine($"Aborting authorization, error received: {error}");
		IsAuthorized = false;
		await _authServer.Stop();
		CallDeferred("emit_signal", nameof(authorization_failed));
	}

	private Track PlayableItemConverter(SpotifyAPI.Web.IPlayableItem playable)
	{
		var track = new Track();
		if (playable is FullTrack fullTrack)
		{
			track.Id = fullTrack.Id;
			track.Title = fullTrack.Name;
			track.Artists = fullTrack.Artists.ConvertAll(a => a.Name);
			track.DurationMs = fullTrack.DurationMs;
			var images = fullTrack.Album.Images.ConvertAll(ImageConverter);
			track.Image = images.Count == 0 ? null : images[0];
		}
		else if (playable is FullEpisode fullEpisode)
		{
			track.Id = fullEpisode.Id;
			track.Title = fullEpisode.Name;
			track.DurationMs = fullEpisode.DurationMs;
			var images = fullEpisode.Images.ConvertAll(ImageConverter);
			track.Image = images.Count == 0 ? null : images[0];
		}
		return track;
	}

	private Track SimpleTrackConverter(SpotifyAPI.Web.SimpleTrack simpleTrack)
	{
		return new Track()
		{
			Id = simpleTrack.Id,
			Title = simpleTrack.Name,
			Artists = simpleTrack.Artists.ConvertAll(a => a.Name),
			DurationMs = simpleTrack.DurationMs,
		};
	}

	private SimpleAlbum SimpleAlbumConverter(SpotifyAPI.Web.SimpleAlbum simpleAlbum)
	{
		var images = simpleAlbum.Images.ConvertAll(ImageConverter);
		return new SimpleAlbum()
		{
			Id = simpleAlbum.Id,
			Title = simpleAlbum.Name,
			Artists = simpleAlbum.Artists.ConvertAll(a => a.Name),
			Image = images.Count == 0 ? null : images[0],
		};
	}

	private Track PlaylistTrackConverter(PlaylistTrack<IPlayableItem> playlistTrack)
	{
		return PlayableItemConverter(playlistTrack.Track);
	}

	private SimplePlaylist PlaylistConverter(SpotifyAPI.Web.SimplePlaylist simplePlaylist)
	{
		var images = simplePlaylist.Images.ConvertAll(ImageConverter);

		var playlist = new SimplePlaylist()
		{
			Id = simplePlaylist.Id,
			Title = simplePlaylist.Name,
			Author = simplePlaylist.Owner.DisplayName,
			Image = images.Count == 0 ? null : images[0],
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

	public class PlayableItemCollectionSearch : Godot.Object
	{
		public List<SimpleAlbum> Albums { get; set; } = new List<SimpleAlbum>();
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
		public List<string> Artists { get; set; }
		public int DurationMs { get; set; }
		public Image Image { get; set; }
	}

	public abstract class PlayableItemCollection : Godot.Object
	{
		public string Id { get; set; }
		public string Title { get; set; }
		public Image Image
		{
			get; set;
		}
	}

	public class SimpleAlbum : PlayableItemCollection
	{
		public List<string> Artists { get; set; } = new List<string>();
	}

	public class SimplePlaylist : PlayableItemCollection
	{
		public string Author { get; set; }
	}
}
