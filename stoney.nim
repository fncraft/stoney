import options
import json
import httpclient
import sequtils
import strutils
import osproc
# types needed for parsing
type Video = object 
    title: string
    url: string
    duration: string
    views: string

type Uploader = object 
    username: string
    url: Option[string]
    verified: Option[bool]

type Result = object
    video: Option[Video]
    uploader: Option[Uploader]

type SearchResult = object
    results: seq[Result]
# search using youtube-scrape
proc search(query: string, client: HttpClient): seq[Result] =
    return to(parseJson(client.getContent("http://youtube-scrape.herokuapp.com/api/search?q=" & query)), SearchResult).results
# validate results
proc validate(res: Result): bool = isSome(res.video) and isSome(res.uploader)
proc print_info(res: Result) =
    if validate(res):
        echo "Title: " & res.video.get().title
        echo "Duration: " & res.video.get().duration
        echo "Views: " & res.video.get().views
        echo "URL: " & res.video.get().url
        echo "Uploader: " & res.uploader.get().username
        if isSome(res.uploader.get().url):
            echo "Uploader URL: " & res.uploader.get().url.get()
        if isSome(res.uploader.get().verified):
            if res.uploader.get().verified.get():
                echo "Uploader is verified"
            else:
                echo "Uploader is not verified"
        else:
            echo "Unknown"

var client = newHttpClient()
var results: seq[Result] 

while true:
    stdout.write("stoney> ")
    var cmd = stdin.readLine()
    if cmd == "exit":
        break
    elif substr(cmd, 0,6) == "search ":
        var query = substr(cmd, 7)
        results = filter(search(query, client), validate)
        for i in 0..len(results) - 1:
            stdout.write($i & ": " & results[i].video.get().title & " (" & results[i].uploader.get().username & ")\n")
    elif substr(cmd, 0, 4) == "info ":
        var index = parseInt(substr(cmd, 5))
        if index >= 0 and index < len(results):
            print_info(results[index])
        else:
            echo "Invalid index"
    elif substr(cmd, 0, 4) == "help":
        echo "Commands:"
        echo "  search <query> - search for videos"
        echo "  info <index> - print info about a video"
        echo "  exit - exit"
    elif substr(cmd,0,5) == "watch ":
        var index = parseInt(substr(cmd,6))
        if index >= 0 and index < len(results):
            var url = results[index].video.get().url
            var _ = osproc.startProcess("mpv", "", [url], options={poUsePath})
        else:
            echo "Invalid index"
    else:
        stdout.write("unknown command\n")