require 'pg'
require_relative '../../lib/errors'

# Metadata for user's general profile (age, location, education, languages).
class About
    TABLE = 'about'.freeze

    attr_reader :id, :age, :location, :education, :languages

    # Initializes an About record with main metadata fields.
    #
    # Parameters:
    # - id: String - unique identifier
    # - age: String|Integer - age value for display
    # - location: String - geographic location/city
    # - education: String - degree/level/major
    # - languages: String - language(s) spoken
    #
    # Returns: About
    def initialize(attrs)
        @id = attrs['id']
        @age = attrs['age']
        @location = attrs['location']
        @education = attrs['education']
        @languages = attrs['languages'] || ''
    end

    # Fetches the first about row from the DB or nil if not present.
    #
    # Parameters:
    # - conn: PG::Connection - database connection
    #
    # Returns: About|nil (if no record found)
    #
    # Raises:
    # - BDError if SQL/database error
    # - DataConsistencyError for logic/data errors
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
