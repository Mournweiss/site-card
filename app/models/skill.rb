require 'pg'
require_relative '../../lib/errors'

class Skill
    TABLE = 'skills'.freeze

    attr_reader :id, :group_id, :name, :level

    def initialize(attrs)
        @id = attrs['id']
        @group_id = attrs['group_id']
        @name = attrs['name']
        @level = attrs['level']
    end

    def self.all_by_group(conn, group_id)
        begin
            conn.exec_params("SELECT * FROM #{TABLE} WHERE group_id = $1 ORDER BY id ASC", [group_id]).map { |row| Skill.new(row) }
        rescue PG::Error => e
            raise BDError.new("DB fetch failed (Skill.all_by_group): #{e.message}", context: {class: 'Skill', method: 'all_by_group', group_id: group_id, original: e})
        rescue => e
            raise DataConsistencyError.new("Skill.all_by_group error: #{e.message}", context: {class: 'Skill', method: 'all_by_group', group_id: group_id, original: e})
        end
    end

    def self.find(conn, id)
        begin
            res = conn.exec_params("SELECT * FROM #{TABLE} WHERE id = $1 LIMIT 1", [id])
            res.ntuples > 0 ? Skill.new(res[0]) : nil
        rescue PG::Error => e
            raise BDError.new("DB fetch failed (Skill.find): #{e.message}", context: {class: 'Skill', method: 'find', id: id, original: e})
        rescue => e
            raise DataConsistencyError.new("Skill.find error: #{e.message}", context: {class: 'Skill', method: 'find', id: id, original: e})
        end
    end
end
