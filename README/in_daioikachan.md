# Daioikachan plugin for Fluentd

This plugin provides [ikachan](https://github.com/yappo/p5-App-Ikachan) compatible interface by Fluentd.

## Installation

Bundled with `daioikachan` gem.

## Configuration

```apache
<source>
  type daioikachan
  bind 127.0.0.1
  port 4979
  backlog 2048

  # optional Puma parameters
  min_threads 0
  max_threads 4
</source>
```

Receiving API post like below,

```
$ curl -d "channel=#channel&message=test message" http://localhost:4979/notice
```

emits an event as

```
notice.channel {"command":"notice","channel":"channel","message":"test message"}
```

## API

### /notice

Send `notice` message.

```
$ curl -d "channel=#channel&message=test message" http://localhost:4979/notice
```

### /privmsg

Send `privmsg` message.

```
$ curl -d "channel=#channel&message=test message" http://localhost:4979/privmsg
```

### /join

The server always returns 200, and ignored.

IRC client should automatically join to a channel on sending message.
Slack client does not require to join to a channel.

### /leave

The server always returns 200, and ignored.
