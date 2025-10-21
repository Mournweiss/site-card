require 'pg'
require_relative '../../lib/errors'

class SkillGroup
    TABLE = 'skill_groups'.freeze

    attr_reader :id, :name

    def initialize(attrs)
        @id = attrs['id']
        @name = attrs['name']
    end

    def self.all(conn)
        begin
            conn.exec("SELECT * FROM #{TABLE} ORDER BY id ASC").map { |row| SkillGroup.new(row) }
        rescue PG::Error => e
            raise BDError.new("DB fetch failed (SkillGroup.all): #{e.message}", context: {class: 'SkillGroup', method: 'all', original: e})
        rescue => e
            raise DataConsistencyError.new("SkillGroup.all fetch error: #{e.message}", context: {class: 'SkillGroup', method: 'all', original: e})
        end
    end

    def self.find(conn, id)
        begin
            res = conn.exec_params("SELECT * FROM #{TABLE} WHERE id = $1 LIMIT 1", [id])
            res.ntuples > 0 ? SkillGroup.new(res[0]) : nil
        rescue PG::Error => e
            raise BDError.new("DB fetch failed (SkillGroup.find): #{e.message}", context: {class: 'SkillGroup', method: 'find', id: id, original: e})
        rescue => e
            raise DataConsistencyError.new("SkillGroup.find error: #{e.message}", context: {class: 'SkillGroup', method: 'find', id: id, original: e})
        end
    end
end
