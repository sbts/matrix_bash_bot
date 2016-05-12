#!/bin/bash

source matrix-bashbot.sh
mkdir -p ~/tmp

clear;

cat <<-EOF
	We update 2 playlists as you enter songs.
	    ~/tmp/mpddj-all.playlist
	    ~/tmp/mpddj-\$playlist.playlist
	where you are about to enter a value for \$playlist
	
	EOF
read -e -i 'default' -p 'Please enter a playlist name: '
touch ~/tmp/mpddj-${playlist:=default}.playlist

clear;

cat <<-EOF
	This script prompts you for a song URL or search string to play
	I then submits your entry to https://half-shot.uk/stream via
	matrix room !mpd:halfshot.uk
	
	enter
	    quit: to exit
	    next: to skip the current song
	    skip: to skip the current song
	
	
	Song:

EOF

while true; do
    tput cup 10 6
    tput ed
    read -e Search
    tput ed
    echo
    case ${Search:-unknown} in
        'quit') echo -e "\n\n";
                exit;;
        'next') ./matrix-bashbot.sh mpddj_skip;;
        'skip') ./matrix-bashbot.sh mpddj_next;;
             *) ./matrix-bashbot.sh mpddj_QueueSong "$Search";;
    esac
    echo
    echo "$Search" >> ~/tmp/mpddj-$playlist.playlist
    echo "$Search" >> ~/tmp/mpddj-all.playlist
    for i in {10..1}; do echo -en "\r  $i   "; sleep 1; done
done


