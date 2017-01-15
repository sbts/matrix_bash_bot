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


    Function List
    ----------------------------------------------------------------------------------------------------------
                      : ######################################################################################
                      : ######################################################################################
                      : USAGE: matrix-bashbot.sh Option|Command [ARG1 [ARG2]]
                      : Options
                      : -v --version : script Version
                      : -h --help    : this help
                      : ######################################################################################
                      : ######################################################################################
                      : ######################################################################################
                      : ######################################################################################
                      : Configuration and Stored State are first obtained from the defaults in the script
                      : Then read from ~/.matrix-bash-bot.rc
                      : NOTE: the location of the rc file can be overridden by setting environment variable
                      : matrix_bash_bot_rc
                      : before running or sourcing matrix-bashbot.sh
                      : Then read from $StateFile
                      : Each source overrides the previous one.
                      : $StateFile is stored in /tmp and is normally deleted on reboot
                      : any state_ variables can be stored in ~/.matrix-bash-bot.rc to provide defaults after a reboot.
                      : but beware, if you do this with the TOKENS and later run the LOGIN function you will
                      : need to manually update them otherwise a subsequent reboot will end up using the wrong TOKENS
                      : A better way of handling this is to make sure you do a login after every reboot.
                      : Eventually we will test for an empty TOKEN every time the script is run, and do an auto login.
                      : ######################################################################################
                      : ######################################################################################

    DIE               : $1 = short message  $2 = detail
                      : print a loud error message and exit

    clear_State       : clear all stored state
                      : if the state is stored in /tmp (the default) then it would normally be cleared on reboot as well

    dump_Functions    : Dump a help style list of functions and Comments starting with ##
                      : to get a function name to be dumped you need to follow the form, foo()  ## comment
                      : All lines that start with "[[:space:]]*## "  will be included regardless of being inside a function or not

    HELP              : This Help Message
                      : print help and current state
                      : Run this with -h --help or HELP

    WRITE_README      : Update the README.md file

    VERSION           : Display the current version of this script
                      : Run this with -V --version or VERSION

    test_rawurlencode : test the rawurlencode() function, prints the result as well as putting it in $URLstring
                      : $1 is the String to Encode

    Register          : Register a new username.
                      : Username is read from "$StateFile" [default: /tmp/matrixbashbot-$USER/state-vars ]
                      : Password is currently stored in this script,
                      : but will soon be read from stdin instead
                      : Should only be called once for a username.
                      : ######################################################
                      : WARNING fixme this function is untested use with caution
                      : ######################################################

    LogIn             : Login to get an access token for your username
                      : the token can be reused essentially forever.
                      : Username is read from "$StateFile" [default: /tmp/matrixbashbot-$USER/state-vars ]
                      : Password is currently stored in this script,
                      : but will soon be read from stdin instead

    JoinRoom          : $1 is room name
                      : joins the given room, appends the home_server (likely :matrix.org) if none is provided
                      : in most cases the room will already be joined, in that case, this function
                      : primarily is used to change the roomID which is used for all other actions

    SendMessage       : $1 is message to send
                      : send a text string to the currently selected room
                      : a default test string with appended date will be used if no string supplied.

    mpddj             : $@ command to send to mpddj
                      : NOTE: all mpddj* commands use a fixed room !mpd:half-shot.uk
                      : skip the currently playing song on http://half-shot.uk/stream via mpddj in room mpd:half-shot.uk
                      : ping Ping the server and get the delay.
                      : current Get the current song title.
                      : next Skip current song.
                      : help This help text.
                      : search Get the first youtube result by keywords.
                      : [url] Type a youtube/soundcloud/file url in to add to the playlist.
                      : stream Get the url of the stream.
                      : playlist Display the the shortened playlist.

    mpddj_QueueSong   : $1 is message to send
                      : queue a song on http://half-shot.uk/stream via mpddj in room mpd:half-shot.uk
                      : a default song will be selected if you don't enter one
                      : if a url is supplied containing http: or https: then it will attempt to play that URL
                      : otherwise it will ask mpddj to search for the song.

    mpddj_next        : no arguments
                      : skip the currently playing song on http://half-shot.uk/stream via mpddj in room mpd:half-shot.uk

    mpddj_skip        : no arguments
                      : skip the currently playing song on http://half-shot.uk/stream via mpddj in room mpd:half-shot.uk

    SetIrcTopic       : This is a crude hack that bypasses setting the matrix topic
                      : and directly tries setting the topic on the IRC side of the bridge.
                      : of course this will only work if your matrix (IRC side) user has OPs
                      : or the channel does not have +t set
                      : on bridged channels, you would normally not have ROOM power to let you change the topic
                      : $1 is new topic

    SetTopic          : change the topic in the matrix room
                      : may aslo change the topic for bridged channels in both matrix and IRC but it is unlikely
                      : as you normally don't have power on the matrix side which will block both sides of the bridge from changing
                      : on bridged channels, you would normally not have ROOM power to let you change the topic
                      : $1 is new topic

    GetInitialSync    : retrieves initialSync date with limit=1 and stores it in /tmp/matrixbashbot-$USER/state-initial-sync
                      : for now nothing else is done with the data, it is just stored in the file

    GetRecentEvents   : this is broken for now, should return the last X events in the current room
                      : ######################################################
                      : WARNING fixme this function is untested use with caution
                      : ######################################################

    DoSync            : runs a sync from the last known event time
                      : ######################################################
                      : WARNING fixme this function is untested use with caution
                      : ######################################################

    GetPushRules      : dump the current PushRules to stdout as formatted JSON

    GetRoomState      : dump the current Roomstate to stdout as formatted JSON

    SampleGets        : some sample gets that don't need authentication
