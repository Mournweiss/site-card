# SPDX-FileCopyrightText: 2025 Maxim Selin <selinmax05@mail.ru>
#
# SPDX-License-Identifier: MIT

require 'pg'
require_relative '../../lib/errors'

# Holds user business-card avatar details (name, role, profile photo extension).
class Avatar
    TABLE = 'avatars'.freeze

    attr_reader :id, :name, :role, :description, :image_ext

    # Initializes an Avatar instance with attributes.
    #
    # Parameters:
    # - id: String - avatar unique identifier
    # - name: String - avatar's full name
    # - role: String - role or position
    # - description: String - bio/description
    # - image_ext: String|null - file extension (png, jpg, jpeg or nil)
    #
    # Returns: Avatar
    def initialize(attrs)
        @id = attrs['id']
        @name = attrs['name']
        @role = attrs['role']
        @description = attrs['description']
        @image_ext = attrs['image_ext']&.downcase
    end

    # Returns user avatar image URL or nil if extension is invalid.
    #
    # Returns: String|nil - URL to image in userdata, or nil if not available
    def image_url
        return nil unless %w[png jpg jpeg].include?(@image_ext)
        "/userdata/avatar.#{@image_ext}"
    end

    # Fetches the first avatar row from DB. Handles PG and other errors.
    #
    # Parameters:
    # - conn: PG::Connection - database connection
    #
    # Returns: Avatar|nil (if not found)
    #
    # Raises:
    # - BDError if a database error occurs
    # - DataConsistencyError for other data/logic errors
    def self.fetch(conn)
        begin
            res = conn.exec("SELECT * FROM #{TABLE} LIMIT 1") rescue nil
            return nil unless res && res.respond_to?(:ntuples)
            res.ntuples > 0 ? Avatar.new(res[0]) : nil
        rescue PG::Error => e
            raise BDError.new("DB fetch failed (Avatar): #{e.message}", context: {class: 'Avatar', method: 'fetch', original: e})
        rescue => e
            raise DataConsistencyError.new("Avatar fetch error: #{e.message}", context: {class: 'Avatar', method: 'fetch', original: e})
        end
    end
end
