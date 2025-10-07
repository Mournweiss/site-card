require 'cgi'
require_relative '../../lib/errors'

class FormHandler
    def initialize(logger, config)
        @logger = logger
        @config = config
    end

    def process_contact_form(request)
        params = parse_params(request)
        errors = validate(params)
        if errors.empty?
            log_submission(params)
            [true, 'Thank you! Your message has been received.']
        else
            raise ValidationError, errors.join(' ')
        end
    end

    private

    def parse_params(request)
        CGI.parse(request.body || '').transform_values(&:first)
    end

    def validate(params)
        errors = []
        errors << 'Name is required.' if params['inputName'].to_s.strip.empty?
        errors << 'Email is required.' if params['inputEmail'].to_s.strip.empty?
        errors << 'Message is required.' if params['inputMessage'].to_s.strip.empty?
        errors
    end

    def log_submission(params)
        @logger.info("Contact form submitted: Name=#{params['inputName']}, Email=#{params['inputEmail']}, Message=#{params['inputMessage']}, To=#{@config.content['contacts']['email']}")
    end
end
