ffmpeg \                                                                                                     255 ↵
    -f video4linux2 -framerate 25 -video_size 1280x960 -i /dev/video0 \
    -c:v libx264 -b:v 1600k -preset ultrafast \
    -x264opts keyint=50 -g 25 -pix_fmt yuv420p \
    -c:a aac -b:a 128k \
    -vf "drawtext=fontfile=/usr/share/fonts/dejavu/DejaVuSans-Bold.ttf: \
text='ALL-SKY CAMERA 01 UTC-3 %{localtime\:%Y-%m-%dT%T}': fontcolor=white@0.8: fontsize=16: x=10: y=10: box=1: boxcolor=black: boxborderw=6" \
    -f flv "rtmp:192.168.1.192:4935/live/cam1?streamkey=5f3e32f3bad0"



