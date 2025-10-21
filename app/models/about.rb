require 'pg'
require_relative '../../lib/errors'

class About
    TABLE = 'about'.freeze

    attr_reader :id, :name, :age, :location, :education, :description, :timezone

    def initialize(attrs)
        @id = attrs['id']
        @name = attrs['name']
        @age = attrs['age']
        @location = attrs['location']
        @education = attrs['education']
        @description = attrs['description']
        @timezone = attrs['timezone']
    end

    def self.fetch(conn)
        begin
            res = conn.exec("SELECT * FROM #{TABLE} LIMIT 1")
            if res.ntuples > 0
                About.new(res[0])
            else
                nil
            end
        rescue PG::Error => e
            raise BDError.new("DB fetch failed (About): #{e.message}", context: {class: 'About', method: 'fetch', original: e})
        rescue => e
            raise DataConsistencyError.new("About fetch error: #{e.message}", context: {class: 'About', method: 'fetch', original: e})
        end
    end
end
