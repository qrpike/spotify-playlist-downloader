

require('coffee-script')

Colors 		= require('colors')
Program 	= require('commander')
Downloader	= require('./lib/downloader')

getUserHome = =>
	if process.platform is 'win32' then return process.env['USERPROFILE']
	return process.env['HOME']

Program
	.version('0.0.1')
	.option('-u, --username [username]', 'Spotify Username (required)', null)
	.option('-p, --password [password]', 'Spotify Password (required)', null)
	.option('-l, --playlist [playlist]', 'Spotify URI for playlist', null)
	.option('-d, --directory [directory]', "Directory you want to save the mp3s to, default: #{getUserHome()}/spotify-mp3s", "#{getUserHome()}/spotify-mp3s")
	.parse( process.argv )



USERNAME = Program.username
PASSWORD = Program.password
PLAYLIST = Program.playlist
DIRECTORY = Program.directory

if !PASSWORD? or !USERNAME?
	console.log '!!! MUST SPECIFY USERNAME & PASSWORD !!!'.red
	return Program.outputHelp()

if !PLAYLIST?
	console.log '!!! MUST SPECIFY A SPOTIFY PLAYLIST !!!'.red
	return Program.outputHelp()



DL = new Downloader( USERNAME, PASSWORD, PLAYLIST, DIRECTORY )