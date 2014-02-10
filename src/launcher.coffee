_server = require '../lib/server.js'

exports.start = (http_port) ->
  server = new _server.Server
  server.startHTTP http_port, ->
    server.loadConfig()
    console.log "Started !"

@start()