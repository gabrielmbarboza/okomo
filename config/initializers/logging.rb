# frozen_string_literal: true

# Structured JSON logging configuration
# Produces structured log output for easier parsing in production.

if Rails.env.production?
  Rails.application.configure do
    config.log_formatter = proc do |severity, timestamp, _progname, msg|
      {
        timestamp: timestamp.iso8601(3),
        level: severity,
        message: msg.to_s.strip,
        app: "okomo",
        environment: Rails.env
      }.to_json + "\n"
    end
  end
end
