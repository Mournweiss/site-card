# SPDX-FileCopyrightText: 2025 Maxim Selin <selinmax05@mail.ru>
#
# SPDX-License-Identifier: MIT

require 'pg'
require_relative '../../lib/errors'

# Work experience records linked to About, models user's professional history.
class Career
    attr_reader :company, :position, :start_date, :end_date

    # Initializes a Career with company info and dates.
    #
    # Parameters:
    # - company: String - employer name
    # - position: String - job title
    # - start_date: String - ISO start date
    # - end_date: String - ISO end date
    #
    # Returns: Career
    def initialize(attrs)
        @company = attrs['company']
        @position = attrs['position']
        @start_date = attrs['start_date']
        @end_date = attrs['end_date']
    end

    # Fetches all career records by about_id ordered by newest first.
    #
    # Parameters:
    # - conn: PG::Connection - database connection
    # - about_id: String|Integer - reference to about record
    #
    # Returns: Array<Career>
    #
    # Raises:
    # - PG::Error for database errors
    def self.all_by_about(conn, about_id)
        res = conn.exec("SELECT * FROM careers WHERE about_id = #{about_id} ORDER BY start_date DESC")
        res.map { |row| Career.new(row) }
    end
end
