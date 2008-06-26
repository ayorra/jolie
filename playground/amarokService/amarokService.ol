include "console.iol"
include "exec.iol"
include "string_utils.iol"

constants {
	DCOPPrefix = "dcop amarok ",
	Location_AmarokService = "socket://localhost:10100"
}

execution { sequential }

inputPort AmarokInput {
OneWay:
	play, pause, previous,
	next, playByIndex, setVolume
RequestResponse:
	getLyrics, getPlaylist,
	getNowPlaying, getVolume
}

outputPort EventManager {
Notification:
	register,
	unregister,
	registerForAll,
	fireEvent
}

outputPort Poller {
Notification:
	setEventManagerLocation,
	start, setAmarokServiceLocation
}

embedded {
Jolie:
	"services/EventManager.ol" in EventManager,
	"amarokPoller.ol" in Poller
}

service AmarokService {
Location: Location_AmarokService
Protocol: sodep
Ports: AmarokInput
Redirects {
	EventManager => EventManager
}
}

init
{
	setEventManagerLocation@Poller( EventManager.location );
	setAmarokServiceLocation@Poller( Location_AmarokService );
	start@Poller()
}

main
{
	[ play( request ) ] {
		exec@Exec( DCOPPrefix + "player play" )()
	}
	
	[ pause( request ) ] {
		exec@Exec( DCOPPrefix + "player pause" )()
	}

	[ previous( request ) ] {
		exec@Exec( DCOPPrefix + "player prev" )()
	}

	[ next( request ) ] {
		exec@Exec( DCOPPrefix + "player next" )()
	}

	[ getVolume()( response ) {
		exec@Exec( DCOPPrefix + "player getVolume" )( response );
		trim@StringUtils( response )( response )
	} ] { nullProcess }

	[ setVolume( request ) ] {
		exec@Exec( DCOPPrefix + "player setVolume " + request )()
	}

	[ getNowPlaying( request )( response ) {
		exec@Exec( DCOPPrefix + "player isPlaying" )( isPlaying );
		trim@StringUtils( isPlaying )( isPlaying );
		if ( isPlaying == "false" ) {
			response = "Paused"
		} else {
			exec@Exec( DCOPPrefix + "player nowPlaying" )( response );
			trim@StringUtils( response )( response )
		}
	} ] { nullProcess }

	[ getPlaylist( request )( response ) {
		exec@Exec( DCOPPrefix + "playlist filenames" )( s );
		s.regex = "\n";
		split@StringUtils( s )( ss );
		for( i = 0, i < #ss.result, i++ ) {
			response.song[i] = ss.result[i]
		}
	} ] { nullProcess }

	[ getLyrics( request )( response ) {
		exec@Exec( DCOPPrefix + "player lyrics" )( response )
	} ] { nullProcess }

	[ playByIndex( request ) ] {
		exec@Exec( DCOPPrefix + "playlist playByIndex " + request.index )()
	}
}

