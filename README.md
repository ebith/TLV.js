# TLV.js
Tiarraのログをブラウザで見れるやつ。検索はできなくなった。

- Server-Sent EventsとVue.jsでリロード要らず
- Web Speech APIで最新の発言を読み上げる
- コストの割に使わないのでElasticsearchを使った全文検索はやめた

## 付属品
### importer.rb
既存のログをMongDBに流しこむためのスクリプト。
`ruby importer.rb /home/ebith/tiarra/log/hoge`とかして使う。  
ログの保存設定に依存するのでたぶんあんまり使えない。

### Mongo.pm
[tiarraMetro付属のDBI.pm](https://github.com/tyoro/tiarraMetro/blob/master/misc/DBI.pm)を書き換えてMongoDBに書き込むようにしたやつ。  
Tiarraのmodule/Log/に配置してconfに以下のように書いて使う。
```
+ Log::Mongo {
  charset: utf8
  channel: *
}
```

## SendMessage.pm
[tiarraMetro付属のSendMessage.pm](https://github.com/tyoro/tiarraMetro/blob/master/misc/SendMessage.pm)にLog::MongoとLog::Recent用の部分もコピペしたやつ。
