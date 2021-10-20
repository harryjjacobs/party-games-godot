using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading.Tasks;
using SpotifyAPI.Web.Http;

public class HTTPResponse : Godot.Object, IResponse
{
    public object Body { get; set; }

    public IReadOnlyDictionary<string, string> Headers { get; set; }

    public HttpStatusCode StatusCode { get; set; }

    public string ContentType { get; set; }
}

public class MusiQHTTPClient : Godot.Object, IHTTPClient
{
    private Godot.HTTPClient godotHttpClient = new Godot.HTTPClient();
    private TimeSpan requestTimeout = TimeSpan.FromSeconds(60);
    private bool cancelRequest = false;
    private static Queue<IRequest> requestsQueue = new Queue<IRequest>();

    public void CancelCurrentRequest()
    {
        if (requestsQueue.Count > 0)
        {
            cancelRequest = true;
        }
    }

    public Task<IResponse> DoRequest(IRequest request)
    {
        return Task.Run(() =>
        {
            requestsQueue.Enqueue(request);
            while (requestsQueue.Peek() != request)
            {
                Godot.OS.DelayMsec(100);
            }
            var response = PerformHttpRequest(request);
            requestsQueue.Dequeue();
            cancelRequest = false;
            return response;
        });
    }

    public void SetRequestTimeout(TimeSpan timeout)
    {
        requestTimeout = timeout;
    }

    private IResponse PerformHttpRequest(IRequest request)
    {
        var response = new HTTPResponse();

        Godot.Error err;

        Godot.GD.Print("Host: " + request.BaseAddress.Host);
        err = godotHttpClient.ConnectToHost(request.BaseAddress.Host, -1, true);
        if (err != Godot.Error.Ok)
        {
            Godot.GD.PrintErr("Connect to host error: ", err);
            return response;
        }

        Godot.GD.Print("Connecting to host " + request.BaseAddress.Host);

        var startTime = DateTime.Now;
        while (godotHttpClient.GetStatus() == Godot.HTTPClient.Status.Connecting || 
                godotHttpClient.GetStatus() == Godot.HTTPClient.Status.Resolving)
        {
            godotHttpClient.Poll();
            Godot.OS.DelayMsec(10);
            if ((DateTime.Now - startTime) > requestTimeout || cancelRequest)
            {
                cancelRequest = false;
                return response;
            }
        }

        if (godotHttpClient.GetStatus() == Godot.HTTPClient.Status.Connected)
        {
            Godot.GD.Print("Connected");
        }
        else
        {
            Godot.GD.PrintErr("HTTP client failed to connect to host");
            return response;
        }

        string requestBody = "";
        if (request.Body != null)
        {
            Godot.GD.Print("Request Body: " + request.Body);
            requestBody = request.Body.ToString();
        }

        // Some headers.
        var requestHeaders = new List<string>(new[] { "User-Agent: Pirulo/1.0 (Godot)", "Accept: */*" });
        if (requestBody.Length == 0)
        {
            requestHeaders.Add("Content-Length: 0");
        }
        foreach (var header in request.Headers)
        {
            var headerValue = header.Key + ": " + header.Value;
            requestHeaders.Add(headerValue);
            // Godot.GD.Print(headerValue);
        }

        var endpointUrl = ApplyParameters(new Uri(request.BaseAddress, request.Endpoint), request.Parameters).PathAndQuery;

        var method = SystemHttpMethodToGodotHttpMethod(request.Method);
        err = godotHttpClient.Request(method, endpointUrl, requestHeaders.ToArray(), requestBody);
        if (err != Godot.Error.Ok)
        {
            Godot.GD.PrintErr("Request failed: ", err);
            return response;
        }

        Godot.GD.Print(request.Method.Method + " " + endpointUrl);

        // Keep polling for as long as the request is being processed.
        while (godotHttpClient.GetStatus() == Godot.HTTPClient.Status.Requesting)
        {
            godotHttpClient.Poll();
            Godot.OS.DelayMsec(10);
            if ((DateTime.Now - startTime) > requestTimeout || cancelRequest)
            {
                cancelRequest = false;
                return response;
            }
        }

        // Make sure the request finished well.
        if (godotHttpClient.GetStatus() != Godot.HTTPClient.Status.Body && godotHttpClient.GetStatus() != Godot.HTTPClient.Status.Connected)
        {
            Godot.GD.PrintErr("Error during request: ", err);
            return response;
        }

        // Godot.GD.Print("Response? ", godotHttpClient.HasResponse());

        // If there is a response...
        if (godotHttpClient.HasResponse())
        {
            var statusCode = godotHttpClient.GetResponseCode();
            response.StatusCode = (HttpStatusCode)statusCode;

            Godot.GD.Print("Response Code: ", statusCode);

            // Godot.GD.Print("Response Headers:");

            var headers = new Dictionary<string, string>();
            foreach (string header in godotHttpClient.GetResponseHeaders())
            {
                var split = header.Split(new string[] { ": " }, StringSplitOptions.None);
                headers[split[0]] = split[1];

                if (split[0] == "Content-Type")
                {
                    response.ContentType = split[1];
                }
                // Godot.GD.Print("\t" + header);
            }
            response.Headers = headers;

            List<byte> rb = new List<byte>();

            // While there is data left to be read
            while (godotHttpClient.GetStatus() == Godot.HTTPClient.Status.Body)
            {
                godotHttpClient.Poll();
                byte[] chunk = godotHttpClient.ReadResponseBodyChunk();
                if (chunk.Length == 0)
                {
                    Godot.OS.DelayMsec(10);
                }
                else
                {
                    rb.AddRange(chunk);
                }
                if ((DateTime.Now - startTime) > requestTimeout || cancelRequest)
                {
                    cancelRequest = false;
                    return response;
                }
            }

            Godot.GD.Print("Body Bytes Downloaded: ", rb.Count);

            var body = Encoding.ASCII.GetString(rb.ToArray());
            response.Body = body;
            // Godot.GD.Print("Response Body: " + body);
        }
        return response;
    }

    private Uri ApplyParameters(Uri uri, IDictionary<string, string> parameters)
    {
        if (parameters == null || parameters.Count == 0)
        {
            return uri;
        }

        var newParameters = ParseQuery(uri.Query);
        foreach (var parameter in parameters)
        {
            newParameters.Add(parameter.Key, Uri.EscapeUriString(parameter.Value));
        }

        var queryString = string.Join("&", newParameters.Select((parameter) => $"{parameter.Key}={parameter.Value}"));
        var query = string.IsNullOrEmpty(queryString) ? null : queryString;

        var uriBuilder = new UriBuilder(uri)
        {
            Query = query
        };

        return uriBuilder.Uri;
    }

    private Dictionary<string, string> ParseQuery(string query)
    {
        var dic = new Dictionary<string, string>();
        var reg = new Regex("(?:[?&]|^)([^&]+)=([^&]*)");
        var matches = reg.Matches(query);
        foreach (Match match in matches)
        {
            dic[match.Groups[1].Value] = Uri.UnescapeDataString(match.Groups[2].Value);
        }
        return dic;
    }

    private Godot.HTTPClient.Method SystemHttpMethodToGodotHttpMethod(System.Net.Http.HttpMethod method)
    {
        var godotMethod = Godot.HTTPClient.Method.Get;
        if (method == System.Net.Http.HttpMethod.Get)
        {
            godotMethod = Godot.HTTPClient.Method.Get;
        }
        else if (method == System.Net.Http.HttpMethod.Post)
        {
            godotMethod = Godot.HTTPClient.Method.Post;
        }
        else if (method == System.Net.Http.HttpMethod.Put)
        {
            godotMethod = Godot.HTTPClient.Method.Put;
        }
        else if (method == System.Net.Http.HttpMethod.Delete)
        {
            godotMethod = Godot.HTTPClient.Method.Delete;
        }
        else if (method == System.Net.Http.HttpMethod.Options)
        {
            godotMethod = Godot.HTTPClient.Method.Options;
        }
        else if (method == System.Net.Http.HttpMethod.Head)
        {
            godotMethod = Godot.HTTPClient.Method.Head;
        }
        else if (method == System.Net.Http.HttpMethod.Trace)
        {
            godotMethod = Godot.HTTPClient.Method.Trace;
        }
        return godotMethod;
    }
}