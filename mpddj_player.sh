#!/bin/bash

source matrix-bashbot.sh

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
    read Search
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
    for i in {10..1}; do echo -en "\r  $i   "; sleep 1; done
done


