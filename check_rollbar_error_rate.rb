#!/usr/bin/ruby
#
# Usage: ruby check_rollbar_error_rate.rb <access_token> <time_window_in_seconds> <warning_error_rate> <critical_error_rate>
# e.g ruby check_rollbar_error_rate.rb N7uiLAE4lnsbQB1blILXvCPGS4tWTNPE 30 60

require 'open-uri'
require 'json'

if ARGV[0].nil?
  puts "Missing access token - usage: `ruby check_rollbar_error_rate.rb <access_token> <time_window_in_seconds> <warning_error_rate> <critical_error_rate>`"
  exit 3
else
  ACCOUNT_ACCESS_TOKEN = ARGV[0].freeze
end

BASE_URI = 'https://api.rollbar.com/api/1/'.freeze

def data_for_endpoint(endpoint, access_token = ACCOUNT_ACCESS_TOKEN, extra_data = {})
  uri = URI(BASE_URI)
  uri.path += endpoint
  uri.query = URI.encode_www_form(extra_data.merge(access_token: access_token))
  JSON.parse(open(uri.to_s).read)['result']
end

time_window = (ARGV[1] || 600).to_i
warning_error_rate = (ARGV[2] || 30).to_i
critical_error_rate = (ARGV[3] || 60).to_i
error_window = (Time.now.to_i - time_window)
critical_errors = []
warnings = []

# Get all projects in an account
projects = data_for_endpoint('projects')

projects.each do |p|
  # Get the access token for a project
  tokens = data_for_endpoint("project/#{p['id']}/access_tokens")
  token_data = tokens.find { |r| r['scopes'].include?('read') }

  next unless token_data

  # Get the last 100 errors in a project
  occurrences = (1..5).each.map do |i|
    page = data_for_endpoint('instances', token_data['access_token'], page: i)
    page['instances']
  end.compact.flatten

  # Get any errors that have occurred within the time window we've specified
  recent_occurrences = occurrences.select { |i| i['timestamp'] > error_window }

  if recent_occurrences.count >= critical_error_rate
    critical_errors << "project #{p['name']} has had >= #{critical_error_rate} errors in the last #{time_window / 60} minutes"
  end

  if recent_occurrences.count >= warning_error_rate
    warnings << "project #{p['name']} has had >= #{warning_error_rate} errors in the last #{time_window / 60} minutes"
  end
end

if critical_errors.count > 0
  puts "ROLLBAR STATUS CRITICAL - #{critical_errors.join('; ')}"
  exit 2
end

if warnings.count > 0
  puts "ROLLBAR STATUS WARNING - #{warnings.join('; ')}"
  exit 1
end

puts "ROLLBAR STATUS OK"
