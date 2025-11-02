# SPDX-FileCopyrightText: 2025 Maxim Selin <selinmax05@mail.ru>
#
# SPDX-License-Identifier: MIT

require 'pg'
require_relative '../../lib/errors'

# Represents a single skill (name, color, level) belonging to a skill group for user display.
class Skill
    TABLE = 'skills'.freeze

    attr_reader :id, :group_id, :name, :level, :color

    # Initializes a Skill entry for the user's skill set.
    #
    # Parameters:
    # - id: String|Integer - skill ID
    # - group_id: String|Integer - reference to skill group
    # - name: String - skill name (e.g., 'Ruby')
    # - level: String|Integer - numeric level or label
    # - color: String - color code for display
    #
    # Returns: Skill
    def initialize(attrs)
        @id = attrs['id']
        @group_id = attrs['group_id']
        @name = attrs['name']
        @level = attrs['level']
        @color = attrs['color']
    end

    # Queries all skills referenced to a group.
    #
    # Parameters:
    # - conn: PG::Connection
    # - group_id: String|Integer
    #
    # Returns: Array<Skill>
    #
    # Raises:
    # - BDError/DataConsistencyError
    def self.all_by_group(conn, group_id)
        begin
            conn.exec_params("SELECT * FROM #{TABLE} WHERE group_id = $1 ORDER BY id ASC", [group_id]).map { |row| Skill.new(row) }
        rescue PG::Error => e
            raise BDError.new("DB fetch failed (Skill.all_by_group): #{e.message}", context: {class: 'Skill', method: 'all_by_group', group_id: group_id, original: e})
        rescue => e
            raise DataConsistencyError.new("Skill.all_by_group error: #{e.message}", context: {class: 'Skill', method: 'all_by_group', group_id: group_id, original: e})
        end
    end

    # Finds one Skill by ID.
    #
    # Parameters:
    # - conn: PG::Connection
    # - id: String|Integer
    #
    # Returns: Skill|nil
    #
    # Raises:
    # - BDError/DataConsistencyError
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
