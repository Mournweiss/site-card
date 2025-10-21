require 'pg'
require_relative '../../lib/errors'

class Experience
    TABLE = 'experiences'.freeze

    attr_reader :id, :label, :value

    def initialize(attrs)
        @id = attrs['id']
        @label = attrs['label']
        @value = attrs['value']
    end

    def self.all(conn)
        begin
            conn.exec("SELECT * FROM #{TABLE} ORDER BY id ASC").map { |row| Experience.new(row) }
        rescue PG::Error => e
            raise BDError.new("DB fetch failed (Experience.all): #{e.message}", context: {class: 'Experience', method: 'all', original: e})
        rescue => e
            raise DataConsistencyError.new("Experience.all error: #{e.message}", context: {class: 'Experience', method: 'all', original: e})
        end
    end

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
