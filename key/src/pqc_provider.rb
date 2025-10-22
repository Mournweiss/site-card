require_relative './errors'

class PQCProvider
    def self.generate_to(outfile)
        begin
            list = `openssl list -public-key-algorithms -provider default 2>&1 | grep -i ML-KEM-1024`
            raise PQCNotSupportedError.new('ML-KEM-1024 not found in OpenSSL', context: {cmd: 'openssl list -public-key-algorithms -provider oqsprovider', output: list.strip}) if list.strip.empty?
            pem_file = outfile + '.pem'
            gen_cmd = "openssl genpkey -provider default -algorithm ML-KEM-1024 -out #{pem_file}"
            cmd_log = `#{gen_cmd} 2>&1`
            exit_code = $?.exitstatus
            unless exit_code == 0 && File.exist?(pem_file)
                raise PQCNotSupportedError.new('ML-KEM keygen via openssl failed', context: {cmd: gen_cmd, path: pem_file, log: cmd_log, exit_code: exit_code})
            end
            der_cmd = "openssl pkey -in #{pem_file} -outform DER -out #{outfile} 2>/dev/null"
            der_log = `#{der_cmd} 2>&1`
            der_exit = $?.exitstatus
            unless der_exit == 0 && File.exist?(outfile)
                raise PQCNotSupportedError.new('ML-KEM DER export failed', context: {cmd: der_cmd, output: der_log, path: outfile})
            end
            File.delete(pem_file) if File.exist?(pem_file)
            return outfile
        rescue PQCNotSupportedError => e
            raise e
        rescue => e
            raise PQCNotSupportedError.new('Failed to generate PQC key', context: {error: e.message, backtrace: e.backtrace&.first(5)})
        end
        raise PQCNotSupportedError.new('Failed to generate PQC key', context: {cmd: 'openssl genpkey/pkey', info: 'outer catch'})
    end
end
