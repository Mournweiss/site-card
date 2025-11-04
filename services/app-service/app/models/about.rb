# SPDX-FileCopyrightText: 2025 Maxim Selin <selinmax05@mail.ru>
#
# SPDX-License-Identifier: MIT

require 'pg'
require_relative '../../lib/errors'

# Metadata for user's general profile (birth date, location, education, languages).
class About
    TABLE = 'about'.freeze

    attr_reader :id, :birth_date, :location, :education, :languages

    # Initializes an About record with main metadata fields.
    #
    # Parameters:
    # - id: String - unique identifier
    # - birth_date: Date|String - date of birth (YYYY-MM-DD)
    # - location: String - geographic location/city
    # - education: String - degree/level/major
    # - languages: String - language(s) spoken
    #
    # Returns: About
    def initialize(attrs)
        @id = attrs['id']
        @birth_date = begin
            v = attrs['birth_date']
            v ? Date.parse(v) : nil
        rescue
            nil
        end
        @location = attrs['location']
        @education = attrs['education']
        @languages = attrs['languages'] || ''
    end

    # Computes age (years) from birth_date.
    #
    # Returns:
    # - Integer|nil - user age in years, or nil if birth_date not set/invalid
    def age
        return nil unless @birth_date
        today = Date.today
        years = today.year - @birth_date.year
        years -= 1 if today.month < @birth_date.month || (today.month == @birth_date.month && today.day < @birth_date.day)
        years
    end

    # Fetches the first about row from the DB or nil if not present
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
