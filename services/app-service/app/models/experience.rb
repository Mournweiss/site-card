require 'pg'
require_relative '../../lib/errors'

# Represents skill/proficiency/metrics for CV charts and display.
class Experience
    TABLE = 'experiences'.freeze

    attr_reader :id, :label, :value

    # Initializes an Experience record for CV/portfolio.
    #
    # Parameters:
    # - id: String|Integer - primary key
    # - label: String - label/title (e.g., 'Ruby', 'Backend')
    # - value: String - score/years/level
    #
    # Returns: Experience
    def initialize(attrs)
        @id = attrs['id']
        @label = attrs['label']
        @value = attrs['value']
    end

    # Returns all experience records in ascending order by id.
    #
    # Parameters:
    # - conn: PG::Connection
    #
    # Returns: Array<Experience>
    #
    # Raises:
    # - BDError or DataConsistencyError
    def self.all(conn)
        begin
            conn.exec("SELECT * FROM #{TABLE} ORDER BY id ASC").map { |row| Experience.new(row) }
        rescue PG::Error => e
            raise BDError.new("DB fetch failed (Experience.all): #{e.message}", context: {class: 'Experience', method: 'all', original: e})
        rescue => e
            raise DataConsistencyError.new("Experience.all error: #{e.message}", context: {class: 'Experience', method: 'all', original: e})
        end
    end

    # Looks up an Experience by ID.
    #
    # Parameters:
    # - conn: PG::Connection
    # - id: String|Integer
    #
    # Returns: Experience|nil
    #
    # Raises:
    # - BDError or DataConsistencyError
    def self.find(conn, id)
        begin
            res = conn.exec_params("SELECT * FROM #{TABLE} WHERE id = $1 LIMIT 1", [id])
            res.ntuples > 0 ? Experience.new(res[0]) : nil
        rescue PG::Error => e
            raise BDError.new("DB fetch failed (Experience.find): #{e.message}", context: {class: 'Experience', method: 'find', id: id, original: e})
        rescue => e
            raise DataConsistencyError.new("Experience.find error: #{e.message}", context: {class: 'Experience', method: 'find', id: id, original: e})
        end
    end
end
