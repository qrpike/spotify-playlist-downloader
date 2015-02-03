
require('coffee-script')

fs 				= require('fs')
async 			= require('async')
lodash			= require('lodash')
util 			= require('util')
colors 			= require('colors')
SpotifyWeb 		= require('spotify-web')
mkdirp 			= require('mkdirp')
Path			= require('path')
program 		= require('commander')
ffmetadata		= require("ffmetadata")
domain			= require('domain')
EventEmitter	= require('events').EventEmitter


Error = ( err )=>
	console.log "#{err}".red
	process.exit(1)

Log = ( msg )=>
	console.log " - #{msg}".green



class Track extends EventEmitter

	constructor: ( @trackId, @Spotify, @directory, @cb, @track = {} )->
		@getTrack()

	getTrack: =>
		@Spotify.get @trackId, ( err, track )=>
			if err then return @cb( err )
			@track = track
			@createDirs()

	createDirs: =>
		dir = Path.resolve( "#{@directory}" )
		artistpath = dir + '/' + @track.artist[0].name.replace(/\//g, ' - ') + '/'
		albumpath = artistpath + @track.album.name.replace(/\//g, ' - ') + ' [' + @track.album.date.year + ']/'
		filepath = albumpath + @track.artist[0].name.replace(/\//g, ' - ') + ' - ' + @track.name.replace(/\//g, ' - ') + '.mp3';

		if fs.existsSync( filepath )
			stats = fs.statSync( filepath )
			if stats.size != 0
				console.log "Already Downlaoded: #{@track.artist[0].name} #{@track.name}".yellow
				return @cb()

		if !fs.existsSync( albumpath )
			mkdirp.sync( albumpath )

		@downloadFile( filepath )

	downloadFile: ( filepath )=>
		Log "Downloading: #{@track.artist[0].name} - #{@track.name}"
		out = fs.createWriteStream( filepath )
		d = domain.create()
		d.on 'error', ( err )=>
			console.log " - - #{err.toString()} ...  { Skipping Track }".red
			return @cb()
		d.run =>
			@track.play().pipe(out).on 'finish', =>
				Log " - DONE: #{@track.artist[0].name} - #{@track.name}"
				@writeMetaData( filepath )

	writeMetaData: ( filepath )=>
		id3 =
			artist: @track.artist[0].name
			album: @track.album.name
			title: @track.name
			date: @track.album.date.year
			track: @track.number
		ffmetadata.write filepath, id3, @cb


class Downloader extends EventEmitter

	constructor: ( @username, @password, @playlist, @directory )->
		@Spotify = null
		@Tracks = []
		console.log 'Downloader App Started..'.green
		async.series [ @attemptLogin, @getPlaylist, @processTracks ], ( err, res )=>
			if err then return Error "#{err.toString()}"
			console.log ' ~ ~ ~ ~ ~ ~ DONEZO ~ ~ ~ ~ ~ ~ ~'.green

	attemptLogin: ( cb )=>
		SpotifyWeb.login @username, @password, ( err, SpotifyInstance )=>
			if err then return Error("Error logging in... (#{err})")
			@Spotify = SpotifyInstance
			cb?()

	getPlaylist: ( cb )=>
		Log 'Getting Playlist Data'
		@Spotify.playlist  @playlist, ( err, playlistData )=>
			if err then return Error("Playlist data error... #{err}")
			Log "Got Playlist: #{playlistData.attributes.name}"
			@Tracks = lodash.map playlistData.contents.items, ( item )=>
				return item.uri
			cb?()

	processTracks: ( cb )=>
		Log "Processing #{@Tracks.length} Tracks"
		async.mapSeries @Tracks, @processTrack, cb

	processTrack: ( track, cb )=>
		TempInstance = new Track( track, @Spotify, @directory, cb )




module.exports = Downloader