express  = require 'express'

moment   = require 'moment'

mongoose =  require 'mongoose'
mongoose.connect 'mongodb://localhost/tiarra'

Log = mongoose.model 'Log', mongoose.Schema({})
Recent = mongoose.model 'Recent', mongoose.Schema({})


app = express()
app.configure ->
  app.use express.basicAuth(process.env.TLV_USER, process.env.TLV_PASS) if process.env.NODE_ENV is'production'
  app.set 'port', process.env.PORT || 3000
  app.set 'views', __dirname + '/views'
  app.set 'view engine', 'jade'
  app.use express.favicon()
  app.use express.logger('dev')
  app.use express.bodyParser()
  app.use express.methodOverride()
  app.use app.router
  app.use require('connect-assets')()
  app.use express.static(__dirname + '/public')


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
  getRecent req.query.page, req.query.limit, (log) ->
    res.json log

getLog = (year, month, day, skip=0, limit=50, callback) ->
  targetDay = new Date year, month-1, day
  nextDay = moment([year, month-1, day]).add('days', 1).toDate()
  Log.find({timestamp: {$gte: targetDay, $lt: nextDay}}).lean().sort({timestamp: -1}).skip(skip).limit(limit).exec (err, docs) ->
    callback parseLog docs

searchLog = (word, skip=0, limit=0, callback) ->
  Log.find({log: new RegExp(word, 'i')}).lean().sort({timestamp: -1}).skip(skip).limit(limit).exec (err, docs) ->
    callback parseLog docs

getRecent = (page=1, limit=50, callback) ->
  skip = (page - 1) * 50
  Log.find().lean().sort({timestamp: -1}).skip(skip).limit(limit).exec (err, docs) ->
    callback parseLog docs

parseLog = (docs) ->
  oldstamp = moment 0
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
      msg: line.log
    }


if process.env.NODE_ENV is 'production'
  https = require 'https'
  fs = require 'fs'
  options = {
    key: fs.readFileSync process.env.KEY_PATH
    cert: fs.readFileSync process.env.CRT_PATH
  }
  https.createServer(options, app).listen app.get('port')
else
  http = require 'http'
  http.createServer(app).listen app.get('port')
