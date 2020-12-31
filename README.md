# NGINX RTMP/RTMPS to HLS and MPEG-Dash media stream broadcaster

This is a Docker image to compile, configure and serve NGINX 1.19.6 with the [RTMP module](https://github.com/arut/nginx-rtmp-module/) to support authenticated and encrypted [RTMP/RTMPS](https://en.wikipedia.org/wiki/Real-Time_Messaging_Protocol) media stream as intake, and broadcast [HLS](https://en.wikipedia.org/wiki/HTTP_Live_Streaming) and [MPEG-Dash](https://en.wikipedia.org/wiki/Dynamic_Adaptive_Streaming_over_HTTP) streams to multiple simultaneous users on the internet.

**Warnings**  
1. I've created a dummy SSL certificate/key pair and included it on `./ssl`. Be sure to use a different/real one if you're going to run this on production.

2. Be sure to edit the `$arg_streamkey` and `$arg_watchkey` values on the `nginx.conf` file, so it will use your own secret "stream key" and "watch key". The default `$arg_streamkey` is `5f3e32f3bad0`, and the `$arg_watchkey` is `16356b9f`.

3. Mind that you will have to rebuild the image for those changes to take effect.

## Running

Build the image:
```
$ docker-compose build streamer
```

Turn on the NGINX server:
```
$ docker-compose up streamer
```

This will bind the `4080`, `4443`, `4080` and `4936` ports to your host machine, so the host will act as the NGINX server.

## Streaming (Publish video stream)

The address to stream follows the format:
```
<protocol>:<nginx-server-address>:<port>/live/<media-name>?streamkey=<stream-key>
```

- `<protocol>`: Either `rtmp` or `rtmps`.
- `<nginx-server-address>`: The IP/DNS of the NGINX server.
- `<port>`: Use `4935` for `rtmp`, and `4936` for `rtmps`.
- `<media-name>`: Choose a unique URL-compliant name.
- `<stream-key>`: The streaming key, defaults to `5f3e32f3bad0`.

**Examples:**
- `rtmps:192.168.1.192:4936/live/myvideo?streamkey=5f3e32f3bad0`
- `rtmp:192.168.1.192:4935/live/othervideo?streamkey=5f3e32f3bad0`

### Streaming a .mp4 file (in loop) using FFmpeg

Over RTMP:
```
$ ffmpeg \
  -stream_loop -1 \
  -i sample.mp4 \
  -f flv "rtmp:192.168.1.192:4935/live/testing?streamkey=5f3e32f3bad0"
```

Over RTMPS:
```
$ ffmpeg \
  -stream_loop -1 \
  -i sample.mp4 \
  -f flv "rtmps:192.168.1.192:4936/live/testing?streamkey=5f3e32f3bad0"
```

### Streaming an USB webcam live feed (audio and video) using FFmpeg

Over RTMP:
```
ffmpeg \
    -f video4linux2 -framerate 25 -video_size 1280x720 -i /dev/video0 \
    -f alsa -ac 2 -i sysdefault:CARD=WEBCAM \
    -c:v libx264 -b:v 1600k -preset ultrafast \
    -x264opts keyint=50 -g 25 -pix_fmt yuv420p \
    -c:a aac -b:a 128k \
    -vf "drawtext=fontfile=/usr/share/fonts/dejavu/DejaVuSans-Bold.ttf: \
text='CLOUD DETECTION CAMERA 01 UTC-3 %{localtime\:%Y-%m-%dT%T}': fontcolor=white@0.8: fontsize=16: x=10: y=10: box=1: boxcolor=black: boxborderw=6" \
    -f flv "rtmp:192.168.1.192:4935/live/mycam?streamkey=5f3e32f3bad0"
```

Over RTMPS:
```
ffmpeg \
    -f video4linux2 -framerate 25 -video_size 1280x720 -i /dev/video0 \
    -f alsa -ac 2 -i sysdefault:CARD=WEBCAM \
    -c:v libx264 -b:v 1600k -preset ultrafast \
    -x264opts keyint=50 -g 25 -pix_fmt yuv420p \
    -c:a aac -b:a 128k \
    -vf "drawtext=fontfile=/usr/share/fonts/dejavu/DejaVuSans-Bold.ttf: \
text='CLOUD DETECTION CAMERA 01 UTC-3 %{localtime\:%Y-%m-%dT%T}': fontcolor=white@0.8: fontsize=16: x=10: y=10: box=1: boxcolor=black: boxborderw=6" \
    -f flv "rtmps:192.168.1.192:4936/live/mycam?streamkey=5f3e32f3bad0"
```

## Watching (Play video stream)

For the .mp4 file example, this would be the secure HLS watching address:  
`https://192.168.1.192:4443/hls/testing.m3u8?watchkey=16356b9f`

And this would be the MPEG-Dash one:  
`https://192.168.1.192:4443/dash/testing.mpd?watchkey=16356b9f`

But you can also watch them without end-to-end encryption:  
HLS - `http://192.168.1.192:4080/hls/testing.m3u8?watchkey=16356b9f`  
Dash - `http://192.168.1.192:4080/dash/testing.mpd?watchkey=16356b9f`

However I don't recommend using this for production. Mind the stream and watch keys will be sent as plain-text on such connections.

You can insert these addresses (changing to match your server IP) on the [VLC](https://www.videolan.org/vlc/index.html) network stream connection address input (`Ctrl + N`) to watch the stream. All HLS and Dash clients are supported, check for one on your application store if you don't want to use VLC.

It also works on the browser, check for Web/JavaScript HLS and Dash clients; I recommend checking [Google's Shaka](https://github.com/google/shaka-player) Dash player.

Here follows a more complete information about these addresses.

### Watching in HLS

The HLS watching address follows the format:
```
<protocol>://<nginx-server-address>:<port>/hls/<media-name>.m3u8?watchkey=<watch-key>
```

- `<protocol>`: Either `http` or `https`.
- `<nginx-server-address>`: The IP/DNS of the NGINX server.
- `<port>`: Use `4080` for `http`, and `4443` for `https`.
- `<media-name>`: The `media-name` of the stream.
- `<watch-key>`: The watching key, defaults to `16356b9f`.

**Examples:**
- `https://192.168.1.192:4443/hls/myvideo.m3u8?watchkey=16356b9f`
- `http://192.168.1.192:4080/hls/othervideo.m3u8?watchkey=16356b9f`

### Watching in MPEG-Dash (preferred)

The Dash watching address follows the format:
```
<protocol>://<nginx-server-address>:<port>/dash/<media-name>.mpd?watchkey=<watch-key>
```

- `<protocol>`: Either `http` or `https`.
- `<nginx-server-address>`: The IP/DNS of the NGINX server.
- `<port>`: Use `4080` for `http`, and `4443` for `https`.
- `<media-name>`: The `media-name` of the stream.
- `<watch-key>`: The watching key, defaults to `16356b9f`.

**Examples:**
- `https://192.168.1.192:4443/dash/myvideo.mpd?watchkey=16356b9f`
- `http://192.168.1.192:4080/dash/othervideo.mpd?watchkey=16356b9f`

## License

These configuration files are available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
