require 'pg'
require_relative '../../lib/errors'

class Contact
    TABLE = 'contacts'.freeze

    attr_reader :id, :type, :value, :label

    def initialize(attrs)
        @id = attrs['id']
        @type = attrs['type']
        @value = attrs['value']
        @label = attrs['label']
    end

    def self.all(conn)
        begin
            conn.exec("SELECT * FROM #{TABLE} ORDER BY id ASC").map { |row| Contact.new(row) }
        rescue PG::Error => e
            raise BDError.new("DB fetch failed (Contact.all): #{e.message}", context: {class: 'Contact', method: 'all', original: e})
        rescue => e
            raise DataConsistencyError.new("Contact.all error: #{e.message}", context: {class: 'Contact', method: 'all', original: e})
        end
    end

    def self.find(conn, id)
        begin
            res = conn.exec_params("SELECT * FROM #{TABLE} WHERE id = $1 LIMIT 1", [id])
            res.ntuples > 0 ? Contact.new(res[0]) : nil
        rescue PG::Error => e
            raise BDError.new("DB fetch failed (Contact.find): #{e.message}", context: {class: 'Contact', method: 'find', id: id, original: e})
        rescue => e
            raise DataConsistencyError.new("Contact.find error: #{e.message}", context: {class: 'Contact', method: 'find', id: id, original: e})
        end
    end
end
