require_relative './errors'

class KeyValidator
    MIN_BYTES = 256
    def self.validate!(filepath)
        unless filepath && File.exist?(filepath)
            raise KeyValidationError.new("Key file #{filepath.inspect} does not exist")
        end
        size = File.size(filepath)
        if !size || size < MIN_BYTES
            raise KeyValidationError.new("Key file is too short (#{size || 0} bytes, min #{MIN_BYTES})")
        end
        true
    end
end
