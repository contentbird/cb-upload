require 'mocha'
should    = require 'should'
request   = require 'request'
sinon     = require 'sinon'
_server   = require '../lib/server.js'
aws2js    = require 'aws2js'
fs        = require 'fs'

http      = require 'http'

describe 'Server', ->
  subject = new _server.Server

  describe '#startHTTP', ->
    it 'respond 200 to http requests on given port number', (done) ->
      subject.startHTTP 5001, ->
        request 'http://localhost:5001', (err, res, body) ->
          should.not.exist(err)
          res.statusCode.should.equal 200
          body.should.equal "Hello from ContentBird Upload"
          done()

    it 'respond 200 and serve blank.gif requests on /ping', (done) ->
      subject.startHTTP 5001, ->
        request 'http://localhost:5001/ping', (err, res, body) ->
          should.not.exist(err)
          res.statusCode.should.equal 200
          res.headers['content-type'].should.equal 'image/gif'
          res.body.should.equal fs.readFileSync('assets/blank.gif').toString()
          done()

  describe '#resize_image', ->
    readEnvFile = (callback) ->
      conf = {}
      fs.readFile '.env', (err, data) =>
        ary = data.toString().split("\n")
        for line in ary
          line_array = line.split('=')
          conf[line_array[0]] = line_array[1]
        callback(conf)

    it 'should upload a resized jpg image and return its path and dimensions', (done) ->
      readEnvFile (conf) ->
        subject.startHTTP 5002, =>
          subject.loadConfig(conf.S3_KEY, conf.S3_SECRET, conf.IMAGE_BUCKET)
          s3 = aws2js.load 's3', conf.S3_KEY, conf.S3_SECRET
          s3.setBucket conf.IMAGE_BUCKET
          s3.put 'test/image_source.jpeg', {'content-type': 'image/jpeg', 'x-amz-acl': 'public-read'}, {'file': './fixtures/image_source.jpeg'}, ->
            request ("http://localhost:5002/resize_image?image=#{encodeURIComponent('test/image_source.jpeg')}&callback=jsonp1234"), (err, res, body) ->
              should.not.exist(err)
              res.statusCode.should.equal 200
              jsonString = JSON.stringify({ "key": "test/image_source_thumb.jpg", "width": 500, "height": 375 })
              body.should.equal "jsonp1234(#{jsonString})"
              done()

    it 'should return status 200 with an error in the json body if S3 credentials are wrong', (done) ->
      subject.startHTTP 5002, =>
        subject.loadConfig('', '', '')
        request ("http://localhost:5002/resize_image?image=#{encodeURIComponent('test/image_source.jpeg')}&callback=jsonp1234"), (err, res, body) ->
          should.not.exist err
          res.statusCode.should.equal 200
          should.exist JSON.parse(res.body)['error']
          done()

    it 'should return status 200 with an error in the json body if original image is not found', (done) ->
      readEnvFile (conf) ->
        subject.startHTTP 5002, =>
          subject.loadConfig(conf.S3_KEY, conf.S3_SECRET, conf.IMAGE_BUCKET)
          request ("http://localhost:5002/resize_image?image=#{encodeURIComponent('test/image_not_found.jpg')}&callback=jsonp1234"), (err, res, body) ->
            should.not.exist err
            res.statusCode.should.equal 200
            should.exist JSON.parse(res.body)['error']
            done()

    it 'should return status 200 with an error in the json body if imagemagick tricks fail', (done) ->
      readEnvFile (conf) ->
        subject.startHTTP 5002, =>
          subject.loadConfig(conf.S3_KEY, conf.S3_SECRET, conf.IMAGE_BUCKET)
          s3 = aws2js.load 's3', conf.S3_KEY, conf.S3_SECRET
          s3.setBucket conf.IMAGE_BUCKET
          s3.put 'test/false_image.txt', {'content-type': 'image/jpeg', 'x-amz-acl': 'public-read'}, {'file': './fixtures/false_image.txt'}, ->
            request ("http://localhost:5002/resize_image?image=#{encodeURIComponent('test/false_image.txt')}&callback=jsonp1234"), (err, res, body) ->
              should.not.exist err
              res.statusCode.should.equal 200
              should.exist JSON.parse(res.body)['error']
              done()

  afterEach ->
    subject.stop()