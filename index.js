const argv = require('minimist')(process.argv.slice(2));
const mongoClient = require('mongodb').MongoClient;
const express = require('express');
const moment = require('moment');
const path = require('path');

mongoClient.connect('mongodb://localhost:27017/tiarra', (err, db) => {
  const recents = db.collection('recents');
  const logs = db.collection('logs');

  const app = express();
  app.set('trust proxy', 'loopback');
  app.use(express.static(path.join(__dirname, 'public')));

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

  app.listen(argv.port || 21877, () => {});
});
