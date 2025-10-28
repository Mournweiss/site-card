require 'pg'
require_relative '../../lib/errors'

class Avatar
    TABLE = 'avatars'.freeze

    attr_reader :id, :name, :role, :description, :image_ext

    def initialize(attrs)
        @id = attrs['id']
        @name = attrs['name']
        @role = attrs['role']
        @description = attrs['description']
        @image_ext = attrs['image_ext']&.downcase
    end

    def image_url
        return nil unless %w[png jpg jpeg].include?(@image_ext)
        "/assets/images/avatar.#{@image_ext}"
    end

    def self.fetch(conn)
        begin
            res = conn.exec("SELECT * FROM #{TABLE} LIMIT 1")
            res.ntuples > 0 ? Avatar.new(res[0]) : nil
        rescue PG::Error => e
            raise BDError.new("DB fetch failed (Avatar): #{e.message}", context: {class: 'Avatar', method: 'fetch', original: e})
        rescue => e
            raise DataConsistencyError.new("Avatar fetch error: #{e.message}", context: {class: 'Avatar', method: 'fetch', original: e})
        end
    end
end
