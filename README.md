# Daioikachan

[Ikachan](https://github.com/yappo/p5-App-Ikachan) compatible interface with multiple backends (IRC, Slack, etc).

## Requirements

* Ruby

## Installation

Write Gemfile:

```
source "https://rubygems.org"

gem 'daioikachan'
```

Run:

```
$ bundle
```

IRC, Slack backends are bundled as default.

Daioikachan supports plugin architecture. You may add your favirite backends as gems. See Plugin section for details.

## How to Run

This is an example to post messages for both IRC and Slack.

### Start

Generate a sample `daioikachan.conf`:

```
$ bundle exec daioikachan -g daioikachan.conf
```

Create `.env` and configure your IRC server and Slack token:

```
IRC_SERVER=XX.XX.XX.XX
SLACK_API_TOKEN=XXX-XXXXX-XXXXXX-XXXXX
````

Start `daioikachan` as

```
$ bundle exec daioikachan
```

### Test

Test to post a message to `daioikachan` like:

```
$ curl -d "channel=#channel&message=test message" http://localhost:4979/notice
```

Look whether posting to IRC, and Slack succeeds.

## Configuration

See [examples](./examples) directory.

You might've noticed that the config file is similar with Fluentd.
Yes, `daioikachan` is created based on Fluentd.
So, you can use `routing` functions which Fluentd has (`tag` and `label`).

See [config-file](http://docs.fluentd.org/articles/config-file) documentation of Fluentd for details.

See following pages for built-in plugins.

* [fluent-pluign-daioikachan](https://github.com/sonots/fluent-plugin-daioikachan)
* [fluent-plugin-irc](https://github.com/choplin/fluent-plugin-irc)
* [fluent-plugin-slack](https://github.com/sowawa/fluent-plugin-slack)

If you need other backends, search other fluentd output plugins and add them. Enjoy!

## Plugin

You can create and add your own backends for daioikachan as a Fluentd Plugin.

See http://www.fluentd.org/plugins#notifications for available plugins.

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

The server always returns 200, and ignore.

IRC client (`fluent-plugin-irc`) automatically joins to a channel on sending message.
Slack client does not require to join to a channel.

### /leave

The server always returns 200, and ignores.

## ChangeLog

See [CHANGELOG.md](CHANGELOG.md) for details.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new [Pull Request](../../pull/new/master)

## Copyright

### daioikachan, and fluent-plugin-daioikachan

Copyright (c) 2015 Naotoshi Seo. See [LICENSE](LICENSE) for details.

### fluent-plugin-irc

See https://github.com/choplin/fluent-plugin-irc

### fluent-plugin-slack

See https://github.com/sowawa/fluent-plugin-slack
