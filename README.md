# Check Rollbar Error Rate

A small script to check the error rate in [Rollbar][rollbar] projects across a single account and return the expected [return code][return_code].

Intended to be plugged into Icinga or similar.

## Usage

```bash
ruby check_rollbar_error_rate.rb <access_token> <time_window_in_seconds> <warning_error_rate> <critical_error_rate>
```

[rollbar]: https://rollbar.com/
[return_code]: https://www.monitoring-plugins.org/doc/guidelines.html#AEN78
