require 'pg'
require_relative '../../lib/errors'

class About
    TABLE = 'about'.freeze

    attr_reader :id, :age, :location, :education, :languages

    def initialize(attrs)
        @id = attrs['id']
        @age = attrs['age']
        @location = attrs['location']
        @education = attrs['education']
        @languages = attrs['languages'] || ''
    end

    def self.fetch(conn)
        begin
            res = conn.exec("SELECT * FROM #{TABLE} LIMIT 1")
            res.ntuples > 0 ? About.new(res[0]) : nil
        rescue PG::Error => e
            raise BDError.new("DB fetch failed (About): #{e.message}", context: {class: 'About', method: 'fetch', original: e})
        rescue => e
            raise DataConsistencyError.new("About fetch error: #{e.message}", context: {class: 'About', method: 'fetch', original: e})
        end
    end
end
