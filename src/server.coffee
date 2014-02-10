http    = require 'http'
url     = require 'url'
aws2js  = require 'aws2js'
Buffers = require 'buffers'
spawn   = require('child_process').spawn
fs      = require 'fs'

class @Server
  @constructor: () ->

  #Start HTTP Server async on localhost
  startHTTP: (http_port, callback) ->
    port = parseInt(process.env.PORT) || http_port || 5000

    requestHandler = (req, res) =>
      url_parts       = url.parse req.url, true
      image_path      = url_parts.query.image
      jsonp_callback  = url_parts.query.callback

      if url_parts.pathname == '/resize_image'
        @resizeAvatar image_path, (error, path, width, height) ->
          if error
            json = JSON.stringify({"error": error.toString()})
            res.writeHead 200, {"Content-Type": "text/html"}
            res.end json
          else
            json = JSON.stringify({"key": path, "width": width, "height": height})
            res.writeHead 200, {"Content-Type": "application/json"}
            res.end "#{jsonp_callback}(#{json})"
      else if url_parts.pathname == '/ping'
        img = fs.readFileSync 'assets/blank.gif'
        res.writeHead 200, {'Content-Type': 'image/gif' }
        res.end img, 'binary'
      else
        res.writeHead 200, {"Content-Type": "text/html"}
        res.end 'Hello from ContentBird Upload'

    @httpServer = http.createServer requestHandler
    @httpServer.listen Number(port), ->
      callback()

  loadS3= (key, secret, bucket) ->
    s3 = aws2js.load 's3', key, secret
    s3.setBucket bucket
    return s3

  convertImage= (image_stream, callback) ->
    args = '-resize 500x500 jpg:-'
    proc = spawn 'convert', ['-'].concat(args.split(' '))
    proc.stderr.on 'data', (err) ->
      return callback err.toString(), null
    proc.on 'error', (err) ->
      return callback err.toString(), null

    image_stream.pipe(proc.stdin)
    buffer = new Buffers()

    proc.stdout.on 'data', buffer.push.bind(buffer)

    proc.stdout.on 'end', ->
      callback null, buffer


  getDimensions= (buffer, callback) ->
    proc2 = spawn 'identify', ['-']
    proc2.stderr.on 'data', (err) ->
      return callback err.toString(), null, null
    proc2.stdin.write buffer.toBuffer()
    proc2.stdin.end()

    proc2.stdout.on 'data', (result) ->
      dimensions = result.toString().match /JPEG (\d*)x(\d*)/
      callback null, parseInt(dimensions[1]), parseInt(dimensions[2])

  resizeAvatar: (image_path, callback) ->
    @s3 = loadS3(@s3_key, @s3_secret, @avatar_bucket)
    try
      @s3.get image_path, 'stream', (err, res) =>
        return callback(err.toString(), null, null, null) if err

        convertImage res, (err, image_buffer) =>
          return callback(err.toString(), null, null, null) if err
          path    = image_path.split('.')[0] + '_thumb.jpg'
          headers = { 'content-type': 'image/jpeg', 'x-amz-acl': 'public-read' }
          width = 0
          height = 0

          getDimensions image_buffer, (err, img_width, img_height) =>
            return callback(err.toString(), null, null, null) if err
            width = img_width
            height = img_height

            @s3.putBuffer path, image_buffer.toBuffer(), false, headers, (err) ->
              return callback(err.toString(), null, null, null) if err
              callback(null, path, width, height)
    catch err
      callback(err.toString(), null, null, null)

  loadConfig: (s3_key=null, s3_secret=null, avatar_bucket=null) ->
    @s3_key         = s3_key        || process.env.S3_KEY
    @s3_secret      = s3_secret     || process.env.S3_SECRET
    @avatar_bucket  = avatar_bucket || process.env.IMAGE_BUCKET

  stop: ->
    @httpServer.close()