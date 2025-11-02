# SPDX-FileCopyrightText: 2025 Maxim Selin <selinmax05@mail.ru>
#
# SPDX-License-Identifier: MIT

require 'pg'
require_relative '../../lib/errors'

# Stores user or site contact methods (e.g., email, telegram) and meta info for UI display.
class Contact
    TABLE = 'contacts'.freeze

    attr_reader :id, :type, :value, :label, :icon

    # Initializes a Contact instance with full metadata.
    #
    # Parameters:
    # - id: String|Integer - contact unique identifier
    # - type: String - type of contact method (e.g., 'email', 'telegram')
    # - value: String - contact address, URL, or handle
    # - label: String - user-friendly label
    # - icon: String - identifier for icon display
    #
    # Returns: Contact
    def initialize(attrs)
        @id = attrs['id']
        @type = attrs['type']
        @value = attrs['value']
        @label = attrs['label']
        @icon = attrs['icon']
    end

    # Fetches all contact records.
    #
    # Parameters:
    # - conn: PG::Connection - database connection
    #
    # Returns: Array<Contact>
    #
    # Raises:
    # - BDError, DataConsistencyError on DB error
    def self.all(conn)
        begin
            conn.exec("SELECT * FROM #{TABLE} ORDER BY id ASC").map { |row| Contact.new(row) }
        rescue PG::Error => e
            raise BDError.new("DB fetch failed (Contact.all): #{e.message}", context: {class: 'Contact', method: 'all', original: e})
        rescue => e
            raise DataConsistencyError.new("Contact.all error: #{e.message}", context: {class: 'Contact', method: 'all', original: e})
        end
    end

    # Finds a Contact by its ID.
    #
    # Parameters:
    # - conn: PG::Connection - database connection
    # - id: String|Integer - primary key
    #
    # Returns: Contact|nil
    #
    # Raises:
    # - BDError, DataConsistencyError on error
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
