require 'pg'
require_relative '../../lib/errors'

class Career
    def self.all_by_about(conn, about_id)
        res = conn.exec("SELECT * FROM careers WHERE about_id = #{about_id} ORDER BY start_date DESC")
        res.map { |row| Career.new(row) }
    end

    def initialize(attrs)
        @company = attrs['company']
        @position = attrs['position']
        @start_date = attrs['start_date']
        @end_date = attrs['end_date']
    end

    attr_reader :company, :position, :start_date, :end_date
end
