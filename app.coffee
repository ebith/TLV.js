config = require './config'
express = require 'express'
moment = require 'moment'
mongoose = require 'mongoose'
net = require 'net'
dns = require 'dns'

mongoose.connect 'mongodb://localhost/tiarra'
Log = mongoose.model 'Log', mongoose.Schema({})
Recent = mongoose.model 'Recent', mongoose.Schema({})

app = express()
app.configure ->
  app.enable 'trust proxy'
  app.use express.basicAuth(config.username, config.password) if config.basic_auth
  app.set 'port', config.port || 3000
  app.set 'views', __dirname + '/views'
  app.set 'view engine', 'jade'
  app.use express.favicon()
  app.use express.logger('dev')
  app.use express.bodyParser()
  app.use express.methodOverride()
  app.use app.router
  app.use require('connect-assets')()
  app.use express.static(__dirname + '/public')

if config.ssl
  https = require 'https'
  fs = require 'fs'
  options = {
    key: fs.readFileSync config.ssl_key
    cert: fs.readFileSync config.ssl_crt
  }
  httpServer = https.createServer(options, app).listen app.get('port')
else
  http = require 'http'
  httpServer = http.createServer(app).listen app.get('port')

app.get '/', (req, res) ->
  res.render 'index', {title: false}

app.get '/:year/:month/:day/?', (req, res) ->
  ymd = [req.params.year, req.params.month, req.params.day]
  getLog ymd[0], ymd[1], ymd[2], 0, 0, (log) ->
    res.render 'day', {title: ymd.join('/'), log: log}

app.get '/search/:word/?.:format?', (req, res) ->
  searchLog req.params.word, req.query.skip, req.query.limit, (log) ->
    log.unshift {info: "search/#{req.params.word}"}
    if req.params.format is 'json'
        res.json log
    else
        res.render 'search', {title: req.params.word, log: log}

app.get '/recent.json', (req, res) ->
  getRecent req.query.skip, req.query.limit, (log) ->
    res.json log

app.get '/stream.json', (req, res) ->
  stream = ''
  req.socket.setTimeout Infinity
  res.writeHead 200, {
    'Content-Type': 'text/event-stream'
    'Cache-Control': 'no-cache'
    'Connection': 'keep-alive'
  }
  res.write '\n'
  req.on 'close', -> stream.destroy()
  Recent.findOne().sort({$natural: -1}).exec (err, item) ->
    stream = Recent.find().lean().gt('_id', item._id).sort({$natural: 1}).tailable().stream()
    oldstamp = ''
    stream.on 'data', (doc) ->
      oldstamp = doc.timestamp
      msg = JSON.stringify(parseLog [doc], moment oldstamp)
      res.write 'data: '+ msg + '\n\n'
  setInterval (-> res.write ': keep-alive\n\n'), 15 * 1000

app.post '/say/?', (req, res) ->
  msg = """
    NOTIFY System::SendMessage TIARRACONTROL/1.0\r\n
    Sender: TLV.js\r\n
    Notice: #{req.body.notice is 'yes' ? 'no'}\r\n
    Channel: #{req.body.channel ? config.default_channel}\r\n
    Charset: UTF-8\r\n
    Text: #{req.body.text}\r\n
    \r\n
    """
  socket = net.connect {path: '/tmp/tiarra-control/tiarra'}, ->
    socket.write msg
    res.send 200

app.get '/info/?', (req, res) ->
  info = {}
  ip = req.ip
  dns.reverse ip, (err, hostnames) ->
    info = {
      ip: ip
      hostname: if hostnames then hostnames[0] else ip
    }
    res.json info

getLog = (year, month, day, skip=0, limit=50, callback) ->
  targetDay = new Date year, month-1, day
  nextDay = moment([year, month-1, day]).add('days', 1).toDate()
  Log.find({timestamp: {$gte: targetDay, $lt: nextDay}}).lean().sort({timestamp: -1}).skip(skip).limit(limit).exec (err, docs) ->
    callback parseLog docs

searchLog = (word, skip=0, limit=0, callback) ->
  Log.find({log: new RegExp(word, 'i')}).lean().sort({timestamp: -1}).skip(skip).limit(limit).exec (err, docs) ->
    callback parseLog docs

getRecent = (skip=0, limit=50, callback) ->
  Recent.find().lean().sort({$natural: -1}).skip(skip).limit(limit).exec (err, docs) ->
    callback parseLog docs

parseLog = (docs, oldstamp=moment 0) ->
  log = docs.reverse().map (line) ->
    timestamp = moment line.timestamp
    date = timestamp.format('YYYY/MM/DD') if timestamp.clone().millisecond(0).second(0).minute(0).hour(0).diff(oldstamp.millisecond(0).second(0).minute(0).hour(0), 'days') > 0
    oldstamp = timestamp
    return {
      isNotice: line.is_notice
      date: date ? null
      info: info ? null
      time: timestamp.format('HH:mm')
      nick: line.nick
      msg: addTag line.log
    }

addTag = (text) ->
  if (urls = /((?:https?|ftp):\/\/\S+)/.exec text)
    for url in urls[1..(urls.length)]
      return text.replace url, "<a href=\"#{url}\" target=\"_blank\">#{url}</a>"
  return text
