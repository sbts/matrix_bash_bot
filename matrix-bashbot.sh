#!/bin/bash

# sure. just grab them out of the network inspector in Chrome or Firefox
# you find the request (search for 'login' or 'm14' for login & message respectively)
# and right-click and copy as curl

# If you want a doc, there's http://matrix.org/docs/howtos/client-server.html
# Another option is to go into the browser console and type localStorage.getItem("mx_access_token")

## ########################################################################################
## ########################################################################################
##
## USAGE: matrix-bashbot.sh Option|Command [ARG1 [ARG2]]
##
##   Options
##     -v --version : script Version
##     -h --help    : this help
##
## ########################################################################################
## ########################################################################################

VERBOSE="${VERBOSE:-false}"
# #####################
# These variables should be set in ~/.matrix-bash-bot.rc
# DO NOT SET THEM IN THIS FILE !!!! It would be a security risk to do so
# #####################
userNAME='username'
userPASSWORD='password'

# #####################
# These variables can either be set here or in ~/.matrix-bash-bot.rc
# #####################
    # default TOPIC to use when changing topic
    # _DATE_ will be replaced with the result of the date command
TOPIC="set by Matrix BashBot at _DATE_"

# #####################
# These variables are automatically maintained by the script and stored in $StateFile
# #####################
state_roomNAME='#test-bot:matrix.org'
state_baseURL='https://matrix.org/_matrix/client'
state_roomID='!ewOgZEUrOZAAaQJNBv:matrix.org'
state_msgID='x'
state_txnID=1

state_home_server="matrix.org"
#state_user_id="@user:matrix.org"

state_accessTOKEN='xxxxxx'
state_refreshTOKEN='xxxxxx'

## ########################################################################################
## ########################################################################################
## .
## Configuration and Stored State are first obtained from the defaults in the script
## Then read from ~/.matrix-bash-bot.rc
##    NOTE: the location of the rc file can be overridden by setting environment variable 
##          MATRIXBASHBOT_RC
##          before running or sourcing matrix-bashbot.sh
## Then read from $StateFile
## Each source overrides the previous one.
## .
## $StateFile is stored in /tmp and is normally deleted on reboot
## any state_ variables can be stored in ~/.matrix-bash-bot.rc to provide defaults after a reboot.
## but beware, if you do this with the TOKENS and later run the LOGIN function you will 
## .  need to manually update them otherwise a subsequent reboot will end up using the wrong TOKENS
## .  A better way of handling this is to make sure you do a login after every reboot.
## .  Eventually we will test for an empty TOKEN every time the script is run, and do an auto login.
## .
## ENVIRONMENT VARIABLES
## .  MATRIXBASHBOT_RC           - Override the RC file location (~/.matrix-bash-bot.rc)
## .  MATRIXBASHBOT_RC_OVERLAY   - The RC file gets loaded first, then this file allows overrides by simply
## .                               reassigning variables
## .  MATRIXBASHBOT_INSTANCE     - Append an instance name to the $StateFile DIR (/tmp/matrixbashbot-$USER)
## .                               so it looks like    /tmp/matrixbashbot-$USER-$MATRIXBASHBOT_INSTANCE
## .
## ########################################################################################
## ########################################################################################

DIE() { ## $1 = short message  $2 = detail
    ## print a loud error message and exit
    cat <<-EOF
	==================================
	==================================
	====  ERROR ERROR ERROR ERROR ====
	==================================
	==================================
	====                          ====`echo $'\r'`====  $1
	==================================
	$2
	==================================
	==================================
	
	EOF
    exit
}

vecho() {
    $VERBOSE && echo $@
}

read COLUMNS < <(tput cols)
export COLUMNS

# #####################
# Work out if we were executed or sourced
# and if sourced make sure it was from a bash shell
# #####################
if [[ ${FUNCNAME[0]} == "source" ]]; then SOURCED=true; else SOURCED=false; fi

ScriptName="${ARGV:-$0}"
if [[ ${BASH##*/} != "bash" ]]; then
    echo "This script '$ScriptName' is intended to only be run from bash"
    exit 1
fi

# #####################
# Check for Args and warn if non available
# #####################
if [[ -z $1 ]] && ! $SOURCED; then
    cat <<-EOF
	    
	    ===============================================================
	    ==  You probably want to run this with at least one argument ==
	    ===============================================================
	    ==  -h or --help will show you available arguments           ==
	    ===============================================================
	    
	EOF
fi

# #####################
# Read User Config
# #####################
rcFile="${MATRIXBASHBOT_RC:=$HOME/.matrix-bash-bot.rc}";
if [[ -r "$rcFile" ]]; then
    source "$rcFile";   # read local config from file
    chmod 600 "$rcFile"  || { DIE "'$ScriptName' said" "failed to own my RC file ($rcFile)"; exit; } # force it to only be readable/writeable by owner
fi

# Read User Config Overlay
rcFile_overlay="${MATRIXBASHBOT_RC_OVERLAY}";
if [[ -r "$rcFile_overlay" ]]; then
    source "$rcFile_overlay";   # read local config from file
    chmod 600 "$rcFile_overlay"  || { DIE "'$ScriptName' said" "failed to own my rc overlay file ($rcFile_overlay)"; exit; } # force it to only be readable/writeable by owner
fi

StateDir="/tmp/matrixbashbot-$USER${MATRIXBASHBOT_INSTANCE:+-$MATRIXBASHBOT_INSTANCE}"
StateFile="$StateDir/state-vars"
File_InitialSync="$StateDir/state-initial-sync"
mkdir -p "$StateDir"

if [[ ! -r $StateFile ]]; then
    chown -R $USER:$USER "$StateDir/" || { DIE "'$ScriptName' said" "failed to own my state file ($StateFile)"; exit; }
fi

# #####################
# Load stored state from file
# #####################
if [[ -r $StateFile ]]; then
    vecho "reading statefile"
    chmod 600 $StateFile # force it to only be readable/writeable by owner
    source "$StateFile"
else
    echo "statefile is missing"
fi

# #####################
# Report Config and State Load Order
# #####################
$VERBOSE && cat <<-EOF
	**********************************************
	** Loaded Config and state from these files
	**     $rcFile
	**     $rcFile_overlay
	**     $StateFile
	**********************************************
	EOF

#state_txnID=1
MSG='Test from matrix bashbot';
#curl 'https://matrix.org/_matrix/client/r0/rooms/!cURbafjkfsMDVwdRDQ%3Amatrix.org/send/m.room.message/m1455740925390?access_token=censored' \
#    -X PUT --data-binary '{"msgtype":"m.text","body":"sure. just grab them out of the network inspector in Chrome or Firefox"}'

if [[ ! -x `which jq` ]]; then 
    if [[ -e `which apt-get` ]]; then
        echo -e " Required tool 'jq' is not available.\n Installing it now\n";
        sudo apt-get install jq;
    else
        echo "Please install Required tool 'jq' then return here and"
        read -p 'Press Enter to continue'
    fi
    # check again now that we have theoretically installed jq
    if [[ ! -x `which jq` ]]; then DIE "jq is not available" "Please install 'jq' and Re-Run this script"; exit; fi
fi

dump_State() {
    echo -e '\n\nCurrent State is'
    for var in ${!state_@}; do
        _val="${!var}"
        if [[ $var =~ 'TOKEN' ]]; then
            if (( ${#_val} > 20 )); then _t="${_val: -10}"; _val="${_val:0:10}....$_t"; fi
        fi
        printf "    %12s = %s\n" "${var#state_}" "$_val"
    done
    echo
}

store_State() {
    vecho -e '\n\nStoring Current State'
    echo -n > "$StateFile"
    if [[ ! -w "$StateFile" ]]; then echo "statefile not writeable"; fi
    for var in ${!state_@}; do
        _val="${!var}"
        if [[ $var =~ 'TOKEN' ]]; then
            if (( ${#_val} > 20 )); then _t="${_val: -10}"; _val="${_val:0:10}....$_t"; fi
        fi
        $VERBOSE && printf "    %12s = %s\n" "${var#state_}" "$_val"
        printf "%s=\"%s\"\n" "${var}" "${!var}" >> "$StateFile"
    done
    vecho
}

clear_State() { ## clear all stored state
    ## if the state is stored in /tmp (the default) then it would normally be cleared on reboot as well
    echo -n "Clearing Stored State: "
    if rm "$StateFile" 2>/dev/null; then echo "DONE"; else echo "FAILED"; fi
}

dump_Functions() { ## Dump a help style list of functions and Comments starting with ##
    ## to get a function name to be dumped you need to follow the form, foo() { ## comment
    ## All lines that start with "[[:space:]]*## "  will be included regardless of being inside a function or not
    while read -t10 F D; do # find max length of any function name
        F="${F#\#\#}"; F="${F/()/}";
        if (( ${#F} > _len )); then _len=${#F}; fi
    done < <(egrep '[a-zA-Z0-9_]+[(][)] {|^[[:space:]]*##' $0)

    if [[ $0 =~ --README ]] || [[ $@ =~ --README ]]; then
        (( _wrap_len = 109 - _len - 7)); # this hopefully is optimal for viewing on GITHUB without scrollbars
    else
        (( _wrap_len = COLUMNS - _len - 7 )); # wrap dynamically based on screen width
    fi

    echo -en '\n    Function List'
    printf  "\n%1.*s\n" $(( _wrap_len + _len + 6 )) '    ----------------------------------------------------------------------------------------------------------'
    while read -t10 F D; do
        F="${F#\#\#}";
        F="${F/()/}";
        D="${D/{/}"
        D=${D# }
        D="${D#\#}"
        D="${D#\#}"
        D="${D# }"
        if [[ -n $F ]]; then echo; fi

        # print Line wrapped to 80 chars
        while (( ${#D} > _wrap_len )); do
            D1="${D:0:$_wrap_len}";     # clip Line to 80 chars
            DlastWord="${D1##*[ #]}"; # save the last word on this line
            if (( ${#DlastWord} >= _wrap_len )); then # if we have a lastword that is all of the line then don't wrap it
                DlastWord=' ';
            else
                DlastWord="${DlastWord:0:$_wrap_len}";
            fi
            D1="${D1%[ #]*}";  # strip the last word off of line 1 (use space as a delimiter)
            D="${DlastWord:0:80}${D:$_wrap_len}"; # prune the first 80 chars from the buffer and prepend the last word from previous line
            printf "    %-*s : %s\n" $_len "$F" "${D1% }";
            F=''; # only print the function name for the first line
            if [[ "$D1" =~ "#${D:0:$_wrap_len}" ]]; then # if the remaining buffer starts with a # and is a perfect subset of the last line printed just drop it
                D='';       # drop the line as it's almost certainly just a series of #'s and either way it already exists on the line above
            else
                D="    $D"; # provide an indent of 4 for wrapped lines
            fi
        done
        if [[ -n $D ]]; then
            printf "    %-*s : %s\n" $_len "$F" "${D}";
        fi

    done < <(egrep '[a-zA-Z0-9_]+[(][)] { ?##|^[[:space:]]*##' $0)
}

HELP() { ## This Help Message
    ## print help and current state
    ## Run this with -h --help or HELP
    clear;
    dump_State;
    dump_Functions;
#    dump_Functions --README;
#    ( declare -p )
#    set -o posix
#    echo 'Current Config is'
#    set
    cat <<-EOF
	
	

	EOF
    exit
}

WRITE_README() { ## Update the README.md file
    cat <<-EOF >README.md
	# matrix_bash_bot
	matrix.org Bash Bot
	
	A Semi-Stateless Matrix Bot written in Bash
	It depends on bash, curl and jq
	
	It is currently far from complete, but is usable to Login, Join a Room, and Send a message to that room
	In theory, you can also register a new user, although this function is untested
	
	Receiving messages is being worked on at the moment.
	
	Other functions will be added when I need them or someone else contributes them.
	
	Some state is stored in /tmp so that consecutive runs don't need to re-login and re-join rooms.
	This allows sending of multiple messages with a simple SendMessage command.
	There is an assumption made here, there will only be one Login Name and one ROOM in use by any System User.
	This is due to the state file being stored in a directory named with the System User appended.
	
	EOF
    dump_Functions >> README.md
}

if ! $SOURCED && { [[ $@ =~ -h ]] || [[ $@ =~ --help ]]; } ; then HELP; fi

VERSION() { ## Display the current version of this script
    ## Run this with -V --version or VERSION
    cat <<-EOF

	===================================================
	===================================================
	====     Version: $Version
	====   CopyRight: SB Tech Services (David G) 2016
	====      Author: David G
	====   matrix id: sbts_mx:matrix.org
	==== matrix room: #sbts:matrix.org
	===================================================
	===================================================

	EOF
    exit
}
if [[ $@ =~ -V ]] || [[ $@ =~ --version ]]; then VERSION; fi
if [[ $@ =~ -v ]] || [[ $@ =~ --verbose ]]; then VERBOSE='true'; fi

rawurlencode() { # URL encode $1
    # Result is returned in $URLstring
  local string="${1}"
  local strlen=${#string}
  local encoded=""

  for (( pos=0 ; pos<strlen ; pos++ )); do
     c=${string:$pos:1}
     case "$c" in
        [-_.~a-zA-Z0-9%] ) o="${c}" ;;
        * )               printf -v o '%%%02x' "'$c"
     esac
     encoded+="${o}"
  done
  #echo "${encoded}"    # You can either set a return variable (FASTER) 
  URLstring="${encoded}"   #+or echo the result (EASIER)... or both... :p
}
test_rawurlencode() { ## test the rawurlencode() function, prints the result as well as putting it in $URLstring
    ## $1 is the String to Encode
    rawurlencode $@
    echo $URLstring
}

Register() { ## Register a new username.
    ## Username is read from "$StateFile" [default: /tmp/matrixbashbot-$USER/state-vars ]
    ## Password is currently stored in this script, 
    ##   but will soon be read from stdin instead
    ## Should only be called once for a username.
    ##
    ## ########################################################
    ## WARNING fixme this function is untested use with caution
    ## ########################################################
    curl -XPOST -d '{"user":"'"$userNAME"'", "password":"'"$userPASSWORD"'", "type":"m.login.password"}' "$state_baseURL/api/v1/register"

    expected_response='{
        "access_token": "QGV4YW1wbGU6bG9jYWxob3N0.AqdSzFmFYrLrTmteXc",
        "home_server": "localhost",
        "user_id": "@example:localhost"
    }'
}

LogIn() { ## Login to get an access token for your username
    ## the token can be reused essentially forever.
    ## Username is read from "$StateFile" [default: /tmp/matrixbashbot-$USER/state-vars ]
    ## Password is currently stored in this script, 
    ##   but will soon be read from stdin instead

    # fixme:
    # should run this block to confirm that m.login.password is supported
    #    curl --location -XGET "$state_baseURL/api/v1/login"
    #    expected_response='{ "flows": [ { "type": "m.login.password" } ] }'

    json='{"type":"m.login.password", "user":"'$userNAME'", "password":"'$userPASSWORD'"}'
    resp=`curl --silent -XPOST -d "$json" "$state_baseURL/api/v1/login"`

    state_accessTOKEN=`jq --raw-output .access_token /dev/stdin <<<$resp`
#dcg_fixme
jq . /dev/stdin <<<$resp
echo -e "\n\n=======\ntoken=$state_accessTOKEN"
#
    #efresh_token is optional in the response
    expected_response='{
        "access_token": "QGV4YW1wbGU6bG9jYWxob3N0.vRDLTgxefmKWQEtgGd",
        "refresh_token": "zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz",
        "home_server": "localhost",
        "user_id": "@example:localhost"
    }'
}

JoinRoom() { ## $1 is room name
    ## joins the given room, appends the home_server (likely :matrix.org) if none is provided
    ## in most cases the room will already be joined, in that case, this function
    ##   primarily is used to change the roomID which is used for all other actions
    roomNAME="${1:-$state_roomNAME}"
    state_roomNAME=$roomNAME
    roomNAME="${roomNAME//#/%23}"
    roomNAME="${roomNAME//@/%40}"
    if [[ $roomNAME == ${roomNAME##*:} ]]; then roomNAME="$roomNAME:$state_home_server"; fi # append the homeserver if there is no server portion to the roomname.
    cat <<-EOF
	============================
	Joining Room '${roomNAME//%23/#}'
	============================
	EOF
#    curl -XPOST -d '{}' "http://localhost:8008/_matrix/client/api/v1/join/%23tutorial%3Alocalhost?access_token=YOUR_ACCESS_TOKEN"
    #curl -XPOST -d '{}' "http://localhost:8008/_matrix/client/api/v1/join/%23tutorial%3Alocalhost?access_token=YOUR_ACCESS_TOKEN"
    resp=`curl --silent -XPOST -d '{}' "$state_baseURL/api/v1/join/${roomNAME}?access_token=$state_accessTOKEN"`
    state_roomID=`jq --raw-output .room_id /dev/stdin <<<$resp`
    if [[ $state_roomID =~ 'null' ]]; then DIE "Invalid Room" "$resp"; fi
    expected_response='{
        "room_id": "!CvcvRuDYDzTOzfKKgh:localhost"
    }'
}

# http://matrix.org/docs/spec/r0.0.1/client_server.html#room-events
SendMessage() { ## $1 is message to send
    ## send a text string to the currently selected room
    ## a default test string with appended date will be used if no string supplied.
    _MSG="${1:-$MSG `date`}"
    state_txnID="`date "+%s"`$(( RANDOM % 9999 ))"
    echo "sending msg '$_MSG' to $state_roomNAME"
    curl "$state_baseURL/r0/rooms/$state_roomID/send/m.room.message/$state_txnID?access_token=$state_accessTOKEN" -X PUT --data-binary '{"msgtype":"m.text","body":"'"$_MSG"'"}'
}

mpddj() { ## $@ command to send to mpddj
    ## NOTE: all mpddj* commands use a fixed room !mpd:half-shot.uk
    ##
    ## skip the currently playing song on http://half-shot.uk/stream via mpddj in room mpd:half-shot.uk
    ## ping Ping the server and get the delay.
    ## current Get the current song title.
    ## next Skip current song.
    ## help This help text.
    ## search Get the first youtube result by keywords.
    ## [url] Type a youtube/soundcloud/file url in to add to the playlist.
    ## stream Get the url of the stream.
    ## playlist Display the the shortened playlist.
    roomName='mpd:half-shot.uk'
    rawurlencode '!gjBxrYiBQltiDameyR:half-shot.uk'
    local roomID="$URLstring"
    _MSG="!mpddj ${@:-help}"
    state_txnID="`date "+%s"`$(( RANDOM % 9999 ))"
    echo "running $_MSG in $roomName"
    echo "you can listen at http://half-shot.uk/stream"
    curl "$state_baseURL/r0/rooms/$roomID/send/m.room.message/$state_txnID?access_token=$state_accessTOKEN" -X PUT --data-binary '{"msgtype":"m.text","body":"'"$_MSG"'"}' > /tmp/matrix-bashbot-mpddj.err 2>&1 && echo "success" || {
        echo "Sending command failed!"
        cat /tmp/matrix-bashbot-mpddj.err
    }
}
mpddj_QueueSong() { ## $1 is message to send
    ## queue a song on http://half-shot.uk/stream via mpddj in room mpd:half-shot.uk
    ## a default song will be selected if you don't enter one
    ## if a url is supplied containing http: or https: then it will attempt to play that URL
    ## otherwise it will ask mpddj to search for the song.
    if [[ $1 =~ 'https?:' ]]; then
        _MSG+="${@:-search lily allen fuck you}";
    else
        _MSG+="search ${@:-lily allen fuck you}";
    fi
    mpddj "$_MSG";
}

mpddj_next() { ## no arguments
    ## skip the currently playing song on http://half-shot.uk/stream via mpddj in room mpd:half-shot.uk
    mpddj next;
}
mpddj_skip() { ## no arguments
    ## skip the currently playing song on http://half-shot.uk/stream via mpddj in room mpd:half-shot.uk
    mpddj next;
}

SetIrcTopic() { ## This is a crude hack that bypasses setting the matrix topic
    ## and directly tries setting the topic on the IRC side of the bridge.
    ## of course this will only work if your matrix (IRC side) user has OPs
    ## or the channel does not have +t set
    ## on bridged channels, you would normally not have ROOM power to let you change the topic
    ## $1 is new topic 
    _MSG="${1:-$TOPIC}"
    _MSG="${_MSG/_DATE_/`date`}"
    state_txnID="`date "+%s"`$(( RANDOM % 9999 ))"
    echo "Setting TOPIC to '$_MSG' on IRC side of $state_roomNAME"
    # This one changes the topic in a bridged IRC channel (if you have rights to do so), but not the matrix room
    curl "$state_baseURL/r0/rooms/$state_roomID/send/m.room.topic/$state_txnID?access_token=$state_accessTOKEN" -X PUT --data-binary '{"topic":"'"$_MSG"'"}'
}

SetTopic() { ## change the topic in the matrix room
    ## may aslo change the topic for bridged channels in both matrix and IRC but it is unlikely
    ## as you normally don't have power on the matrix side which will block both sides of the bridge from changing
    ## on bridged channels, you would normally not have ROOM power to let you change the topic
    ## $1 is new topic
    _MSG="${1:-$TOPIC}"
    _MSG="${_MSG/_DATE_/`date`}"
    state_txnID="`date "+%s"`$(( RANDOM % 9999 ))"
    echo "Setting TOPIC to '$_MSG' on $state_roomNAME"
    # This one changes the topic in a bridged IRC channel (if you have rights to do so), but not the matrix room
    #curl "$state_baseURL/r0/rooms/$state_roomID/send/m.room.topic/$state_txnID?access_token=$state_accessTOKEN" -X PUT --data-binary '{"topic":"'"$_MSG"'"}'
    #this one changes the topic in the matrix room
    curl "$state_baseURL/r0/rooms/$state_roomID/state/m.room.topic?access_token=$state_accessTOKEN" -X PUT --data-binary '{"topic":"'"$_MSG"'"}'
#echo    curl "https://matrix.org/_matrix/client/r0/rooms/!BMQUkvgMwJuteJuqOD%3Amatrix.org/state/m.room.topic?access_token=$state_accessTOKEN" \
#          -X PUT -H 'Host: matrix.org' \
#          -H 'User-Agent: Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:43.0) Gecko/20100101 Firefox/43.0' \
#          -H 'Accept: application/json' \
#          -H 'Accept-Language: en-US,en;q=0.5' \
#          --compressed \
#          -H 'Content-Type: application/json; charset=UTF-8' \
#          -H 'Referer: https://vector.im/develop/' \
#          -H 'Origin: https://vector.im' \
#          -H 'Connection: keep-alive' \
#          --data '{"topic":"test topic"}'
}

SetFilter() {
    
    cat <<-EOF
	look at this http://matrix.org/docs/spec/r0.0.1/client_server.html#filtering
	the main way that filters are used today is to apply limits
	e.g. my vector right here is using {"room":{"timeline":{"limit":20}}}
	based on
	curl 'https://matrix.org/_matrix/client/r0/user/@matthew:matrix.org/filter/21?access_token=secret'
	filter number 21 having been pulled out of looking at what it's using in a /sync request
	EOF
}

GetInitialSync() { ## retrieves initialSync date with limit=1 and stores it in /tmp/matrixbashbot-$USER/state-initial-sync
    ## for now nothing else is done with the data, it is just stored in the file
#    curl -XGET "http://localhost:8008/_matrix/client/api/v1/initialSync?limit=1&access_token=YOUR_ACCESS_TOKEN"
    echo curl --silent -XGET "$state_baseURL/api/v1/initialSync?limit=1&access_token=$state_accessTOKEN"
    curl --silent -XGET "$state_baseURL/api/v1/initialSync?limit=1&access_token=$state_accessTOKEN" > "$File_InitialSync"
    echo "==========================="
    echo "==========================="
    echo "====  results are in   ===="
    echo "==========================="
    echo "$File_InitialSync"
    echo "==========================="
    echo "==========================="
    echo "====    try running    ===="
    echo -e " jq .rooms \"$File_InitialSync\""
#    echo "==== json ===="
#    jq . "$File_InitialSync"
}

GetRecentEvents() { ## this is broken for now, should return the last X events in the current room
    ##
    ## ########################################################
    ## WARNING fixme this function is untested use with caution
    ## ########################################################
    ##
#    curl -XGET "http://localhost:8008/_matrix/client/api/v1/initialSync?limit=1&access_token=YOUR_ACCESS_TOKEN"
    echo curl --silent -XGET "$state_baseURL/api/v1/initialSync?limit=1&access_token=$state_accessTOKEN"
    resp=`curl --silent -XGET "$state_baseURL/api/v1/initialSync?limit=1&access_token=$state_accessTOKEN"`
    echo "==== raw ===="
    echo -e "$resp"
    echo "==== json ===="
    jq . /dev/stdin <<<$resp
}

ConvertAgeToTime() {
    date -u -d @${1} +"%T"
}

ConvertTSToDateTime() {
    date -u -d @${1} +"%F-%T"
}

xMinifyJSON() { :; } # use this to disable a JSON blob that comes after the one you want to use
MinifyJSON() { ## for now just Squashes multiple spaces together. #FIXME: be smarter, including removal of cr/lf etc
    local -g RESULTstring="${1//    / }";
    while [[ "$RESULTstring" =~ '  ' ]]; do
        RESULTstring="${RESULTstring//  / }";
    done
    while [[ "$RESULTstring" =~ $'\r' ]]; do
        RESULTstring="${RESULTstring//$'\r'/}";
    done
    while [[ "$RESULTstring" =~ $'\n' ]]; do
        RESULTstring="${RESULTstring//$'\n'/}";
    done
}

GetEvents_m_room_message() {    ## $1  # last ${1:-1000} events in the current room.
                                ## $2  # starting from the latest event specified by ${2:-END}
                                ## $3  # a json list containing senders to exclude.
                                ##       eg: '"@_neb_github_=40john=3amatrix.freelock.com:matrix.org", "@someuser:matrix.org"'
                                ##       defaults to '"@_neb_github_=40john=3amatrix.freelock.com:matrix.org"'
    ##
    ## ########################################################
    ## WARNING fixme this function is untested use with caution
    ## ########################################################
    ##
    hideToken='hidden' ## comment this out to show the access token in verbose output
    local _From="${2:-END}"; # Token to use for first event to retrieve. Can be 'END' or the token returned in "start" or "end" paramater by a previous request
    local _Dir='b';   # one of 'b' or 'f'. changes direction to retrieve in relation to "from"
    local _Limit=${1:-1000}; # maximum number of events to return
    local _Not_Users="${3:-\"@_neb_github_=40john=3amatrix.freelock.com:matrix.org\"}"
    # a filter to use. This '{"contains_url":true}' only returns events that contain url's # See http://matrix.org/speculator/spec/HEAD/client_server/unstable.html#filtering
    # another example filter https://github.com/turt2live/matrix-voyager-bot/blob/master/src/matrix/filter_template.json
    # this filter doesn't work as expected. the content.msgtype part is ignored
#    MinifyJSON '{
#            "types": ["m.room.message"],
#            "not_senders": ["@_neb_github_=40john=3amatrix.freelock.com:matrix.org"],
#            "content": {
#                "msgtype": ["m.text"]
#            }
#    }';
    MinifyJSON '{
        "types": ["m.room.message"],
        "not_senders": ['${_Not_Users}']
    }';
    rawurlencode "${RESULTstring}"
    local _Filter="${URLstring}"

    vecho "curl --silent -XGET \"$state_baseURL/api/v1/rooms/$state_roomID/messages?access_token=${hideToken:-$state_accessTOKEN}&from=${_From}&dir=${_Dir}&limit=${_Limit}${RESULTstring:+&filter=}${RESULTstring}\"" >/dev/stderr
    resp=` curl --silent -XGET "$state_baseURL/api/v1/rooms/$state_roomID/messages?access_token=$state_accessTOKEN&from=${_From}&dir=${_Dir}&limit=${_Limit}${_Filter:+&filter=}${_Filter}"`
    vecho "==== raw ====" >/dev/stderr
    echo -e "$resp" > /tmp/raw.json
    vecho "== Raw output written to /tmp/raw.json ==" >/dev/stderr
    vecho "==== json ====" >/dev/stderr
    jq . /dev/stdin <<<$resp
    #    jq -r '.chunk[] | select(.age < 86400000) | "\(.age) \(.user_id)"' /dev/stdin <<<$resp
    #    jq -r '.chunk[] | select( .content.msgtype == "m.text" ) | select(.age < 86400000) | "\(.age) \(.user_id) \(.content.body)"' /dev/stdin <<<$resp
}

GetEventLog_24_Hrs() {
    #  FIXME we want to test for jq version >=1.5 then we can use date conversions like....
    #    jq --arg date "2016-04-25" '.[].published_at |= (. / 1000 | strftime("%Y-%m-%d")) | map(select(.published_at == $date))' stuff.json
    local _minAge=0     # seconds
    local _maxAge=86400 # seconds
    GetEvents_m_room_message 1000 >/dev/null
    jq -r --arg maxAge "$_maxAge" '.chunk[] | select( .content.msgtype == "m.text" ) | select(.age < ( $maxAge | tonumber) *1000) | @sh "\(.origin_server_ts/1000) \(.user_id) \(.content.body)"' /dev/stdin <<<$resp # NOTE .age/1000 to convert it to seconds
    jq -r --arg maxAge "$_maxAge" '.chunk[] | select( .content.msgtype == "m.text" ) | select(.age < ( $maxAge | tonumber) *1000) | length' /dev/stdin <<<$resp | wc -l
}

DoSync() { ## runs a sync from the last known event time
    ##
    ## ########################################################
    ## WARNING fixme this function is untested use with caution
    ## ########################################################
    ##
    _since=$state_next_batch
#    _filter='{room{include_leave: "false", account_data:"", timeline:"", ephemeral:"", state:"", not_rooms:"", rooms:"'"$state_roomID"'" }}'
#    rawurlencode '{"room":{"timeline":{"limit":1}}}'
#    rawurlencode '{
#        "event_fields":"content.body",
#        "room":{
#            "include_leave": "false",
#            "timeline":{"limit":1},
#            "rooms":"'"$state_roomID"'"
#        }
#    }'
#    rawurlencode '{"event_fields":"content.body", "room":{"include_leave": "false", "timeline":{"limit":1}, "rooms":"'"$state_roomID"'"}}'
#    rawurlencode '{"presence":{"types":[]}, "event_fields":["content.body"], "room":{"state":{"types":[]}, "timeline":{"limit":1}, "rooms":["'"$state_roomID"'"]}}'
    #rawurlencode '{
    #    "account_data":{"types":[]},
    #    "presence":{"types":[]},
    #    "event_fields":["timeline"],
    #    "room":{
    #        "timeline":{"limit":1},
    #        "rooms":["!pstlCRlhnmqaJggfOM:matrix.org"]
    #    }
    #}'

#    rawurlencode '{
#        "room": {
#            "state": {
#                "types": ["m.room.*"],
#                "not_rooms": ["!726s6s6q:example.com"]
#            },
#            "timeline": {
#                "limit": 2,
#                "types": ["m.room.message"],
#                "not_rooms": ["!726s6s6q:example.com"],
#                "not_senders": ["@spam:example.com"]
#                "rooms":["!pstlCRlhnmqaJggfOM:matrix.org"]
#            },
#            "ephemeral": {
#                "types": [ "m.receipt", "m.typing"],
#                "not_rooms": ["!726s6s6q:example.com"],
#                "not_senders": ["@spam:example.com"]
#            }
#        },
#        "presence": {
#            "types": ["m.presence"],
#            "not_senders": ["@alice:example.com"]
#        },
#        "event_format": "client",
#        "event_fields": ["type", "content", "sender"]
#    }'

#            "rooms":"'"$state_roomID"'"
    rawurlencode '{
        "room": {
            "include_leave": "false",
            "account_data": {},
            "state": {
                "types": [],
                "rooms": []
            },
            "timeline": {
                "limit": 2,
                "types": ["m.room.message"],
                "rooms":["!pstlCRlhnmqaJggfOM:matrix.org"]
            },
            "ephemeral": {
                "types": []
            }
        },
        "event_format": "client",
        "event_fields": ["type", "content.msgtype", "content.body", "sender"],
        "account_data":{
                "types": [],
        },
        "presence":{
                "types": [],
        }
    }'
    _filter="$URLstring"
    curl  -XGET "$state_baseURL/r0/sync?filter=$_filter&timeout=30000&access_token=$state_accessTOKEN" > "$File_InitialSync"
    echo "==========================="
    echo "==========================="
    echo "====  results are in   ===="
    echo "==========================="
    echo "$File_InitialSync"
    echo "==========================="
    echo "==========================="
    echo "====    try running    ===="
    echo -e " jq .rooms \"$File_InitialSync\""
    echo "==========================="

#    jq -C .rooms "$File_InitialSync"


#    curl "https://matrix.org/_matrix/client/r0/sync?filter=7&timeout=30000&since=s14094047_178730_33991_755371_4320&access_token=$state_accessTOKEN" \
#    -H 'Host: matrix.org' \
#    -H 'User-Agent: Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:43.0) Gecko/20100101 Firefox/43.0' \
#    -H 'Accept: application/json' \
#    -H 'Accept-Language: en-US,en;q=0.5' \
#    --compressed \
#    -H 'Referer: https://vector.im/develop/' \
#    -H 'Origin: https://vector.im' \
#    -H 'Connection: keep-alive'
}

GetPushRules() { ## dump the current PushRules to stdout as formatted JSON
    curl "$state_baseURL/r0/pushrules/?access_token=$state_accessTOKEN" | jq .
}

GetRoomState() { ## dump the current Roomstate to stdout as formatted JSON
    echo curl --silent -XGET "$state_baseURL/r0/rooms/{roomId}/state?access_token=$state_accessTOKEN"
    resp=`curl --silent -XGET "$state_baseURL/api/v1/initialSync?limit=1&access_token=$state_accessTOKEN"`
    echo "==== raw ===="
    echo -e "$resp"
    echo "==== json ===="
    jq . /dev/stdin <<<$resp

    GET /_matrix/client/r0/rooms/{roomId}/state
GET /_matrix/client/r0/rooms/{roomId}/state
}


SampleGets() { ## some sample gets that don't need authentication
    local _userId="${1:-@matthew:matrix.org}";
    rawurlencode "$_userId"
    _userId_encoded="$URLstring"

    local _URL="http://${_userId##*:}"

    echo "Public Room List for $_URL"
    echo "More info is available for each room but limited to just the room name here"
    echo "  Also we are limiting to the first 10 rooms incase it's run against a big server like matrix.org"
    wget -q -O /dev/stdout $_URL/_matrix/client/r0/publicRooms | jq '.[] | .[].name' 2>/dev/null | head -n 10;
    echo

    echo "User Profile for user $_userId at $_URL"
    wget -q -O /dev/stdout $_URL/_matrix/client/r0/profile/${_userId_encoded}/profile | jq '.';
    echo

    echo "Avatar URL for user $_userId at $_URL"
    wget -q -O /dev/stdout $_URL/_matrix/client/r0/profile/${_userId_encoded}/avatar_url | jq '.';
    echo
}

if ! $SOURCED; then
    $VERBOSE && dump_State;
fi

"$@"

if ! $SOURCED; then
    store_State
fi
