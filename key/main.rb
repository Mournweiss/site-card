#!/usr/bin/env ruby

require_relative './src/pqc_provider'
require_relative './src/key_validator'
require_relative './src/errors'
require 'securerandom'

begin
    random_part = SecureRandom.hex(16)
    out_path = "/mnt/key/#{random_part}.der"
    begin
        gen_path = PQCProvider.generate_to(out_path)
    rescue PQCNotSupportedError => e
        warn e.to_log
        exit 1
    end
    begin
        KeyValidator.validate!(gen_path)
    rescue KeyValidationError => e
        warn e.to_log
        exit 1
    end
    puts gen_path
rescue => e
    warn KeyGenError.new("CRITICAL #{e.class}: #{e.message}").to_log
    exit 1
end
