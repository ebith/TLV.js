const argv = require('minimist')(process.argv.slice(2));
const mongoClient = require('mongodb').MongoClient;
const express = require('express');
const moment = require('moment');
const path = require('path');
const bodyParser = require('body-parser');
const net = require('net');
const dns = require('dns');

mongoClient.connect('mongodb://localhost:27017/tiarra', (err, db) => {
  const recents = db.collection('recents');
  const logs = db.collection('logs');

  const app = express();
  app.set('trust proxy', 'loopback');
  app.use(express.static(path.join(__dirname, 'public')));
  app.use(bodyParser.urlencoded({ extended: false }));
  app.use(bodyParser.json());

  const formatDocs = (docs) => {
    return docs.map((doc) => {
      const mo = moment(doc.timestamp);
      doc.date = mo.format('YYYY/MM/DD');
      doc.time = mo.format('HH:mm');
      return doc;
    });
  };

  app.get('/stream', function(req, res) {
    req.on('close', () => { stream.destroy(); });
    setInterval((() => res.write(': keep-alive\n\n')), 50 * 1000);
    dns.reverse(req.ip, ((err, hostnames) => {
      const info = {
        info: {
          hostname: hostnames ? hostnames[0] : req.ip
        }
      }
      res.write(`data: ${JSON.stringify(info)}\n\n`);
    }));

    res.writeHead(200, {
      'Content-Type': 'text/event-stream',
      'Cache-Control': 'no-cache',
      'Connection': 'keep-alive'
    });
    res.write(': keep-alive\n\n');

    const query = {
      timestamp: {
        $gt: new Date()
      }
    };
    const options = {
      tailable: true,
      awaitData: true
    };
    const stream = recents.find(query, options).stream();
    stream.on('data', (doc) => {
      res.write(`data: ${JSON.stringify(formatDocs([doc])[0])}\n\n`);
    });
  });

  app.get('/recent.json', (req, res) => {
    recents.find({}).sort({$natural: -1}).skip(req.query.skip-0 || 0).limit(req.query.limit-0 || 50).toArray((err, docs) => {
      res.json(formatDocs(docs.reverse()));
    });
  });

  app.get('/log.json', function(req, res) {
    const currentDay = new Date(req.query.year, req.query.month - 1, req.query.day);
    const query = {
      timestamp: {
        $gte: currentDay,
        $lt: moment(currentDay).add(1, 'days').toDate()
      }
    };
    logs.find(query).sort({timestamp: -1}).toArray((err, docs) => {
      res.json(formatDocs(docs.reverse()));
    });
  });

  app.post('/say', (req,res) => {
    const msg =`NOTIFY System::SendMessage TIARRACONTROL/1.0\r\n
Sender: TLV.js\r\n
Notice: ${req.body.notice ? 'yes' : 'no'}\r\n
Channel: ${req.body.channel ? req.body.channel : argv.channel}\r\n
Charset: UTF-8\r\n
Text: ${req.body.text}\r\n
\r\n`;
    const socket = net.connect('/tmp/tiarra-control/tiarra', () => {
      socket.write(msg);
      socket.end();
      res.sendStatus(200);
    });
  });

  app.listen(argv.port || 21877, () => {});
});
