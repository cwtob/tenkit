# frozen_string_literal: true

require 'jwt'
require 'openssl'
require 'httparty'
require_relative './weather_response'

module Tenkit
  class Client
    include HTTParty
    base_uri 'https://weatherkit.apple.com/api/v1'

    DATA_SETS = {
      current_weather: 'currentWeather',
      forecast_daily: 'forecastDaily',
      forecast_hourly: 'forecastHourly',
      trend_comparison: 'trendComparison',
      weather_alerts: 'weatherAlerts',
      forecast_next_hour: 'forecastNextHour'
    }.freeze

    def availability(lat, lon, country: 'US')
      get("/availability/#{lat}/#{lon}?country=#{country}")
    end

    def weather(lat, lon, data_sets: [:current_weather], language: 'en', daily_start: nil, daily_end: nil, hourly_start: nil, hourly_end: nil)
      path_root = "/weather/#{language}/#{lat}/#{lon}"
      params = []
      params << "dataSets=" + data_sets.map { |ds| DATA_SETS[ds] }.compact.join(',')
      params << "dailyStart=#{daily_start}" if daily_start
      params << "dailyEnd=#{daily_end}" if daily_end
      params << "hourlyStart=#{hourly_start}" if hourly_start
      params << "hourlyEnd=#{hourly_end}" if hourly_end
      path = path_root + "?" + params.join("&")
      # puts "path: #{path}"
      response = get(path)
      WeatherResponse.new(response)
    end

    def weather_alert(id, language: 'en')
      puts 'TODO: implement weather alert endpoint'
      puts language
      puts id
    end

    private

    def get(url)
      headers = { Authorization: "Bearer #{token}" }
      self.class.get(url, { headers: headers })
    end

    def header
      {
        alg: 'ES256',
        kid: Tenkit.config.key_id,
        id: "#{Tenkit.config.team_id}.#{Tenkit.config.service_id}"
      }
    end

    def payload
      {
        iss: Tenkit.config.team_id,
        iat: Time.new.to_i,
        exp: Time.new.to_i + 600,
        sub: Tenkit.config.service_id
      }
    end

    def key
      OpenSSL::PKey.read Tenkit.config.key
    end

    def token
      JWT.encode payload, key, 'ES256', header
    end
  end
end
