# SPDX-FileCopyrightText: 2025 Maxim Selin <selinmax05@mail.ru>
#
# SPDX-License-Identifier: MIT

require 'pg'
require_relative '../../lib/errors'
require_relative 'portfolio_language'
require_relative 'portfolio_tech_badge'

# Represents a portfolio/project entry with metadata, for user showcase.
class Portfolio
    TABLE = 'portfolios'.freeze

    attr_reader :id, :title, :description, :order_index, :url

    # Initializes a Portfolio item with all relevant fields.
    #
    # Parameters:
    # - id: String|Integer - record primary key
    # - title: String - project name
    # - description: String - project description
    # - order_index: String|Integer - display ordering
    # - url: String - remote link for project
    #
    # Returns: Portfolio
    def initialize(attrs)
        @id = attrs['id']
        @title = attrs['title']
        @description = attrs['description']
        @order_index = attrs['order_index']
        @url = attrs['url']
    end

    # Fetches all portfolio items ordered by sort index.
    #
    # Parameters:
    # - conn: PG::Connection
    #
    # Returns: Array<Portfolio>
    #
    # Raises:
    # - BDError, DataConsistencyError on database error
    def self.all(conn)
        begin
            conn.exec("SELECT * FROM #{TABLE} ORDER BY order_index ASC, id ASC").map { |row| Portfolio.new(row) }
        rescue PG::Error => e
            raise BDError.new("DB fetch failed (Portfolio.all): #{e.message}", context: {class: 'Portfolio', method: 'all', original: e})
        rescue => e
            raise DataConsistencyError.new("Portfolio.all error: #{e.message}", context: {class: 'Portfolio', method: 'all', original: e})
        end
    end

    # Finds a portfolio entry by id.
    #
    # Parameters:
    # - conn: PG::Connection
    # - id: String|Integer
    #
    # Returns: Portfolio|nil
    #
    # Raises:
    # - BDError, DataConsistencyError on error
    def self.find(conn, id)
        begin
            res = conn.exec_params("SELECT * FROM #{TABLE} WHERE id = $1 LIMIT 1", [id])
            res.ntuples > 0 ? Portfolio.new(res[0]) : nil
        rescue PG::Error => e
            raise BDError.new("DB fetch failed (Portfolio.find): #{e.message}", context: {class: 'Portfolio', method: 'find', id: id, original: e})
        rescue => e
            raise DataConsistencyError.new("Portfolio.find error: #{e.message}", context: {class: 'Portfolio', method: 'find', id: id, original: e})
        end
    end

    # Returns an array of PortfolioLanguage objects for this portfolio's languages.
    #
    # Parameters:
    # - conn: PG::Connection
    #
    # Returns: Array<PortfolioLanguage>
    #
    # Raises:
    # - BDError/DataConsistencyError on DB error
    def languages(conn)
        begin
            PortfolioLanguage.all_by_portfolio(conn, @id)
        rescue PG::Error => e
            raise BDError.new("DB fetch failed (Portfolio.languages): #{e.message}", context: {class: 'Portfolio', method: 'languages', portfolio_id: @id, original: e})
        rescue => e
            raise DataConsistencyError.new("Portfolio.languages error: #{e.message}", context: {class: 'Portfolio', method: 'languages', portfolio_id: @id, original: e})
        end
    end

    # Returns an array of PortfolioTechBadge objects for this portfolio's badges.
    #
    # Parameters:
    # - conn: PG::Connection
    #
    # Returns: Array<PortfolioTechBadge>
    #
    # Raises:
    # - BDError/DataConsistencyError on error
    def tech_badges(conn)
        begin
            PortfolioTechBadge.all_by_portfolio(conn, @id)
        rescue PG::Error => e
            raise BDError.new("DB fetch failed (Portfolio.tech_badges): #{e.message}", context: {class: 'Portfolio', method: 'tech_badges', portfolio_id: @id, original: e})
        rescue => e
            raise DataConsistencyError.new("Portfolio.tech_badges error: #{e.message}", context: {class: 'Portfolio', method: 'tech_badges', portfolio_id: @id, original: e})
        end
    end
end
