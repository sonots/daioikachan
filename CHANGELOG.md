# 0.0.9 (2015/10/15)

Fixes

* require `rack` (thanks to maroekun)

# 0.0.8 (2015/05/08)

Enhancements

* Add `filter_slack_quote`

# 0.0.7 (2015/04/02)

Fixes:

* filter_string_irc_slack: fix color code replacement

# 0.0.6 (2015/03/31)

Enhancements

* Add `filter_string_irc_slack`
* log.error InternalServerError

# 0.0.5 (2015/03/30)

Changes:

* Use Rack::Request to handle both `application/x-www-form-urlencoded` and `multipart/form-data`.

# 0.0.4 (2015/03/30)

Enhancements:

* Support `multipart/form-data` as ikachan does

# 0.0.3 (2015/03/25)

Changes:

* fluent-plugin-irc v0.0.7 has been released. Use it.

# 0.0.2 (2015/03/23)

Enhancements:

* Fallback to `#{nick}_` when `:err_nick_name_in_use` occurs

# 0.0.1 (2015/03/22)

Initial version

