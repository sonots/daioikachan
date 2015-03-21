# Fluent::Plugin::Irc, a plugin for [Fluentd](http://fluentd.org)

[![Build Status](https://travis-ci.org/choplin/fluent-plugin-irc.svg)](https://travis-ci.org/choplin/fluent-plugin-irc)

Fluent plugin to send messages to IRC server

## Installation

`$ fluent-gem install fluent-plugin-irc`

## Configuration

### Example

```
<match **>
  type irc
  host localhost
  port 6667
  channel fluentd
  nick fluentd
  user fluentd
  real fluentd
  message notice: %s [%s] %s
  out_keys tag,time,message
  time_key time
  time_format %Y/%m/%d %H:%M:%S
  tag_key tag
</match>
```

### Parameter

|parameter|description|default|
|---|---|---|
|host|IRC server host|localhost|
|port|IRC server port number|6667|
|channel|channel to send messages (without first '#')||
|channel_keys|keys used to format channel. %s will be replaced with value specified by channel_keys if this option is used|nil|
|nick|nickname registerd of IRC|fluentd|
|user|user name registerd of IRC|fluentd|
|real|real name registerd of IRC|fluentd|
|message|message format. %s will be replaced with value specified by out_keys||
|out_keys|keys used to format messages||
|time_key|key name for time|time|
|time_format|time format. This will be formatted with Time#strftime.|%Y/%m/%d %H:%M:%S|
|tag_key|key name for tag|tag|
|command|irc command. `privmsg` or `notice`|privmsg|
|command_keys|keys used to format command. %s will be replaced with value specified by command_keys if this option is used|nil|
|send_interval|interval (sec) to send message. defence Excess Flood|2|
|max_send_queue|maximum size of send message queue|100|

## Copyright

<table>
<tr><td>Copyright</td><td>Copyright (c) 2015 OKUNO Akihiro</td></tr>
<tr><td>License</td><td>Apache License, Version 2.0</td></tr>
</table>
