class KeyGenError < StandardError
    attr_reader :context
    def initialize(message = nil, context: {})
        super(message)
        @context = context || {}
    end
    def to_log
        "[#{self.class.name}] #{message} | Context: #{context}"
    end
end

class PQCNotSupportedError < KeyGenError; end
class KeyValidationError < KeyGenError; end
