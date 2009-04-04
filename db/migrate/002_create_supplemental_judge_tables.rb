require 'migration_helper'

class CreateSupplementalJudgeTables < ActiveRecord::Migration
  extend MigrationHelper::ForeignKeys

  def self.up
    create_table :category_preferences, :force => true do |t|
      t.integer :judge_id, :category_id, :null => false
    end
    add_foreign_key :category_preferences, :judge_id, :judges
    add_foreign_key :category_preferences, :category_id, :categories

    create_table :time_availabilities, :force => true do |t|
      t.datetime :start_time, :end_time
      t.integer :judge_id, :null => false
    end
    add_foreign_key :time_availabilities, :judge_id, :judges
  end

  def self.down
    drop_table :time_availabilities
    drop_table :category_preferences
  end

end
