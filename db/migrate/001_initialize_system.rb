require 'active_record/fixtures'
require 'migration_helper'

class InitializeSystem < ActiveRecord::Migration
  extend MigrationHelper::ForeignKeys

  def self.up
    create_table :categories, :force => true do |t|
      t.string  :name, :null => false, :limit => 60
      t.boolean :is_public, :null => false, :default => true
      t.integer :position
    end

    create_table :awards, :force => true do |t|
      t.string  :name, :null => false, :limit => 60
      t.boolean :point_qualifier, :null => false, :default => true
      t.integer :position
      t.references :category, :null => false
    end
    add_foreign_key :awards, :category_id, :categories

    create_table :styles, :force => true do |t|
      t.string  :name, :null => false, :limit => 60
      t.integer :bjcp_category, :null => false
      t.string  :bjcp_subcategory, :null => false, :default => '', :limit => 1
      t.text    :description_url
      t.boolean :mcab_style, :point_qualifier, :null => false, :default => true
      t.boolean :require_carbonation, :require_strength, :require_sweetness,
                :optional_classic_style, :null => false, :default => false
      t.string  :styleinfo, :null => false, :default => 'n', :limit => 1
      t.references :award, :null => false
    end
    add_foreign_key :styles, :award_id, :awards
    add_index :styles, [ :bjcp_category, :bjcp_subcategory ]

    create_table :carbonation, :force => true do |t|
      t.string  :description, :null => false, :limit => 40
      t.integer :position,    :null => false
    end

    create_table :strength, :force => true do |t|
      t.string  :description, :null => false, :limit => 40
      t.integer :position,    :null => false
    end

    create_table :sweetness, :force => true do |t|
      t.string  :description, :null => false, :limit => 40
      t.integer :position,    :null => false
    end

    create_table :judge_ranks, :force => true do |t|
      t.string  :description, :null => false, :limit => 40
      t.boolean :bjcp,        :null => false, :default => true
      t.integer :position,    :null => false
    end

    create_table :point_allocations, :force => true do |t|
      t.integer :min_entries, :null => false
      t.integer :max_entries, :null => false
      t.decimal :organizer, :staff, :judge, :null => false, :precision => 3, :scale => 1
    end

    create_table :countries, :force => true do |t|
      t.string  :name, :null => false, :limit => 80
      # +country_code+ is the ISO 3166 2-character country code.
      t.string  :country_code, :null => false, :limit => 2
      # +postcode_pattern+ defines the format of the country's postal code.
      t.string  :postcode_pattern
      # +postcode_canonify+ defines how a specified postal code, validated
      # against +postcode_pattern+, is canonified before being saved.
      t.string  :postcode_canonify
      # +address_format+ specifies the format of an address.
      t.string  :address_format, :null => false, :default => "%q{\"\#{name}\n\#{address}\n\#{city}\"}"
      # +address_alignment+ specifies whether the address is aligned to the
      # left ('l') or right ('r') or centered ('c') on the envelope.
      t.string  :address_alignment, :null => false, :default => 'l', :limit => 1
      # +region_name+ specifies what the country's regions, if any, are called
      # (e.g., state, province/territory, department, island, etc.).
      t.string  :region_name, :limit => 40
      # +region_name_optional+ flags the rare cases (e.g., Ireland) where a
      # region name is not required in the address.
      t.boolean :region_name_optional, :null => false, :default => false
      # +country_address_name+ specifies the country name to use in the address
      # if it differs from the displayed name (e.g., Guernsey, Guadeloupe).
      t.string  :country_address_name, :limit => 60
      # +is_selectable+ specifies whether the country will be included in a
      # selection list (we're usually only interested in one or, at most, a
      # few countries, not the entire world).
      t.boolean :is_selectable, :null => false, :default => false
    end
    add_index :countries, :country_code
    add_index :countries, :is_selectable

    create_table :regions, :force => true do |t|
      t.string :name, :null => false, :limit => 80
      t.string :region_code, :limit => 6
      t.references :country, :null => false
    end
    add_foreign_key :regions, :country_id, :countries
    add_index :regions, :region_code

    # Create OpenID Tables
    create_table :open_id_authentication_associations, :force => true do |t|
      t.integer :issued, :lifetime
      t.string :handle, :assoc_type
      t.binary :server_url, :secret
    end

    create_table :open_id_authentication_nonces, :force => true do |t|
      t.integer :timestamp, :null => false
      t.string :server_url, :null => true
      t.string :salt, :null => false
    end
    
    # Create Users Table
    create_table :users, :force => true do |t|
      t.string   :login, :null => false, :limit => 40
      t.string   :identity_url, :crypted_password, :salt, :remember_token
      t.string   :name, :limit => 80
      t.string   :email, :limit => 100
      t.boolean  :enabled, :null => false, :default => true
      t.boolean  :is_admin, :is_anonymous, :null => false, :default => false
      t.datetime :remember_token_expires_at
      t.datetime :last_logon_at
      t.timestamps
    end
    add_index :users, :login, :unique => true
    add_index :users, :email

    # Create Passwords Table
    create_table :passwords, :force => true do |t|
      t.string   :reset_code
      t.datetime :expires_at
      t.timestamps
      t.references :user, :null => false
    end
    add_foreign_key :passwords, :user_id, :users

    create_table :roles, :force => true do |t|
      t.string :name, :limit => 60, :null => false
      t.string :description
    end

    create_table :rights, :force => true do |t|
      t.string :name, :null => false, :limit => 60
      t.string :description
      t.string :controller, :action, :null => false, :limit => 40
    end

    create_table :rights_roles, :id => false, :force => true do |t|
      t.references :right, :role, :null => false
    end
    add_foreign_key :rights_roles, :right_id, :rights
    add_foreign_key :rights_roles, :role_id, :roles

    create_table :roles_users, :id => false, :force => true do |t|
      t.references :role, :user, :null => false
    end
    add_foreign_key :roles_users, :role_id, :roles
    add_foreign_key :roles_users, :user_id, :users

    create_table :competition_data, :force => true do |t|
      t.string   :name, :null => false
      t.boolean  :mcab, :null => false, :default => false
      t.string   :local_timezone, :null => false, :default => 'UTC'
      t.date     :competition_date
      t.integer  :competition_number
      t.datetime :competition_start_time_utc
      t.datetime :entry_registration_start_time_utc
      t.datetime :entry_registration_end_time_utc
      t.datetime :judge_registration_start_time_utc
      t.datetime :judge_registration_end_time_utc
    end

    create_table :contacts, :force => true do |t|
      t.string :role,  :null => false, :limit => 40
      t.string :name,  :null => false, :limit => 80
      t.string :email, :null => false, :limit => 100
      t.timestamps
    end

    create_table :clubs, :force => true do |t|
      t.string :name, :null => false, :limit => 80
    end
    add_index :clubs, :name

    create_table :rounds, :force => true do |t|
      t.string  :name,     :null => false, :limit => 20
      t.integer :position, :null => false
    end
    add_index :rounds, :position

    create_table :judging_sessions, :force => true do |t|
      t.string   :description, :null => false
      t.date     :date,        :null => false
      t.integer  :position
      t.datetime :start_time, :end_time
    end
    add_index :judging_sessions, [ :start_time, :end_time ]

    create_table :entrants, :force => true do |t|
      t.string  :first_name, :middle_name, :last_name, :team_name,
                :address1, :address2, :address3, :address4,
                :city,         :null => false, :default => '', :limit => 80
      t.string  :team_members, :null => false, :default => ''
      t.boolean :is_team,      :null => false, :default => false
      t.string  :postcode,     :null => false, :default => '', :limit => 20
      t.string  :email,        :null => false, :default => '', :limit => 100
      t.string  :phone,        :null => false, :default => '', :limit => 40
      t.timestamps
      t.references :region
      t.references :country, :club, :user, :null => false
    end
    add_foreign_key :entrants, :region_id, :regions
    add_foreign_key :entrants, :country_id, :countries
    add_foreign_key :entrants, :club_id, :clubs
    add_foreign_key :entrants, :user_id, :users

    create_table :entries, :force => true do |t|
      t.string  :name, :null => false, :default => '', :limit => 80
      t.text    :style_info, :competition_notes
      t.boolean :odd_bottle, :second_round, :mcab_qe, :null => false, :default => false
      t.integer :bottle_code, :place, :bos_place
      t.boolean :send_award, :send_bos_award
      t.timestamps
      t.references :base_style, :carbonation, :strength, :sweetness
      t.references :entrant, :user, :style, :null => false
    end
    add_foreign_key :entries, :entrant_id, :entrants
    add_foreign_key :entries, :style_id, :styles
    add_foreign_key :entries, :base_style_id, :styles
    add_foreign_key :entries, :carbonation_id, :carbonation
    add_foreign_key :entries, :strength_id, :strength
    add_foreign_key :entries, :sweetness_id, :sweetness
    add_foreign_key :entries, :user_id, :users

    create_table :flights, :force => true do |t|
      t.string   :name, :null => false, :limit => 60
      t.boolean  :assigned, :completed, :null => false, :default => false
      t.datetime :assigned_at, :completed_at
      t.references :round, :award, :null => false
      t.references :judging_session
    end
    add_foreign_key :flights, :round_id, :rounds
    add_foreign_key :flights, :award_id, :awards
    add_foreign_key :flights, :judging_session_id, :judging_sessions

    create_table :entries_flights, :id => false, :force => true do |t|
      t.references :entry, :flight,  :null => false
    end
    add_foreign_key :entries_flights, :entry_id, :entries
    add_foreign_key :entries_flights, :flight_id, :flights
    add_index :entries_flights, [ :entry_id, :flight_id ]

    create_table :judges, :force => true do |t|
      t.string  :first_name, :middle_name, :last_name, :goes_by,
                :address1, :address2, :address3, :address4,
                :city,         :null => false, :default => '', :limit => 80
      t.string  :postcode,     :null => false, :default => '', :limit => 20
      t.string  :email,        :null => false, :default => '', :limit => 100
      t.string  :phone,        :null => false, :default => '', :limit => 40
      t.string  :judge_number, :limit => 10
      t.text    :comments
      t.decimal :staff_points, :precision => 3, :scale => 1
      t.boolean :confirmed
      t.boolean :checked_in, :organizer, :null => false, :default => false
      # NOTE: Length of UUID value (without hyphens) and MD5 key is 32; SHA1 is 40; SHA256 is 64
      t.string  :access_key, :null => false, :default => '', :limit => 32
      t.timestamps
      t.references :region, :country, :club, :judge_rank
      t.references :user, :null => false
    end
    add_foreign_key :judges, :region_id, :regions
    add_foreign_key :judges, :country_id, :countries
    add_foreign_key :judges, :club_id, :clubs
    add_foreign_key :judges, :user_id, :users
    add_foreign_key :judges, :judge_rank_id, :judge_ranks

    create_table :category_preferences, :force => true do |t|
      t.references :judge, :category, :null => false
    end
    add_foreign_key :category_preferences, :judge_id, :judges
    add_foreign_key :category_preferences, :category_id, :categories

    create_table :time_availabilities, :force => true do |t|
      t.datetime :start_time, :end_time
      t.references :judge, :null => false
    end
    add_foreign_key :time_availabilities, :judge_id, :judges

    create_table :judgings, :force => true do |t|
      # Role is either Judge ('j') or Steward ('s'). Note that a judge can have
      # multiple roles in a single competition so the judge's role must be set
      # for each individual flight.
      t.string :role, :null => false, :default => '', :limit => 1
      t.references :flight, :judge, :null => false
    end
    add_foreign_key :judgings, :flight_id, :flights
    add_foreign_key :judgings, :judge_id, :judges

    create_table :scores, :force => true do |t|
      t.decimal :score, :null => false, :precision => 4, :scale => 2
      t.references :entry, :judge, :flight, :null => false
    end
    add_foreign_key :scores, :entry_id, :entries
    add_foreign_key :scores, :judge_id, :judges
    add_foreign_key :scores, :flight_id, :flights

    create_table :news_items, :force => true do |t|
      t.string :title, :null => false
      t.text :description_raw, :description_encoded, :null => false
      t.timestamps
      t.references :author, :null => false
    end
    add_foreign_key :news_items, :author_id, :users

    # Create the table for active_record_store session storage
    create_table :sessions, :force => true do |t|
      t.string :session_id, :null => false
      t.text :data
      t.timestamps
    end
    add_index :sessions, :session_id
    add_index :sessions, :updated_at

    directory = File.join(File.dirname(__FILE__), 'data')
    Fixtures.create_fixtures(directory, 'categories')
    Fixtures.create_fixtures(directory, 'awards')
    Fixtures.create_fixtures(directory, 'styles')
    Fixtures.create_fixtures(directory, 'carbonation')
    Fixtures.create_fixtures(directory, 'strength')
    Fixtures.create_fixtures(directory, 'sweetness')
    Fixtures.create_fixtures(directory, 'judge_ranks')
    Fixtures.create_fixtures(directory, 'point_allocations')
    Fixtures.create_fixtures(directory, 'countries')
    Fixtures.create_fixtures(directory, 'regions')
    Fixtures.create_fixtures(directory, 'users')
    Fixtures.create_fixtures(directory, 'roles')
    Fixtures.create_fixtures(directory, 'rights')
    Fixtures.create_fixtures(directory, 'rights_roles')
    Fixtures.create_fixtures(directory, 'roles_users')
    Fixtures.create_fixtures(directory, 'competition_data')
    Fixtures.create_fixtures(directory, 'contacts')
    Fixtures.create_fixtures(directory, 'clubs')
    Fixtures.create_fixtures(directory, 'rounds')
  end

  def self.down
    drop_table :sessions
    drop_table :news_items
    drop_table :scores
    drop_table :judgings
    drop_table :time_availabilities
    drop_table :category_preferences
    drop_table :judges
    drop_table :entries_flights
    drop_table :flights
    drop_table :entries
    drop_table :entrants
    drop_table :judging_sessions
    drop_table :rounds
    drop_table :clubs
    drop_table :contacts
    drop_table :competition_data
    drop_table :roles_users
    drop_table :rights_roles
    drop_table :rights
    drop_table :roles
    drop_table :passwords
    drop_table :users
    drop_table :regions
    drop_table :countries
    drop_table :point_allocations
    drop_table :judge_ranks
    drop_table :sweetness
    drop_table :strength
    drop_table :carbonation
    drop_table :styles
    drop_table :awards
    drop_table :categories
    drop_table :open_id_authentication_nonces
    drop_table :open_id_authentication_associations
  end

end
