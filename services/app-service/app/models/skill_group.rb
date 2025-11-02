# SPDX-FileCopyrightText: 2025 Maxim Selin <selinmax05@mail.ru>
#
# SPDX-License-Identifier: MIT

require 'pg'
require_relative '../../lib/errors'

# Groups related skills (e.g., languages, frameworks) for user display.
class SkillGroup
    TABLE = 'skill_groups'.freeze

    attr_reader :id, :name

    # Initializes a SkillGroup for grouping related skills.
    #
    # Parameters:
    # - id: String|Integer - primary key/group id
    # - name: String - name for the skill group
    #
    # Returns: SkillGroup
    def initialize(attrs)
        @id = attrs['id']
        @name = attrs['name']
    end

    # Returns all skill groups (sorted).
    #
    # Parameters:
    # - conn: PG::Connection
    #
    # Returns: Array<SkillGroup>
    #
    # Raises:
    # - BDError/DataConsistencyError
    def self.all(conn)
        begin
            conn.exec("SELECT * FROM #{TABLE} ORDER BY id ASC").map { |row| SkillGroup.new(row) }
        rescue PG::Error => e
            raise BDError.new("DB fetch failed (SkillGroup.all): #{e.message}", context: {class: 'SkillGroup', method: 'all', original: e})
        rescue => e
            raise DataConsistencyError.new("SkillGroup.all fetch error: #{e.message}", context: {class: 'SkillGroup', method: 'all', original: e})
        end
    end

    # Finds one SkillGroup by id.
    #
    # Parameters:
    # - conn: PG::Connection
    # - id: String|Integer
    #
    # Returns: SkillGroup|nil
    #
    # Raises:
    # - BDError/DataConsistencyError
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
