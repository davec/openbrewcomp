class CreateEntryScores < ActiveRecord::Migration

  CONTROLLER = 'entry_scores'
  ACTIONS = [ 'read', 'update' ]

  def self.up
    dba_role = Role.find_by_name('Database Admin')
    competition_role = Role.find_by_name('Competition Admin')

    ACTIONS.each do |action|
      right = Right.create(:name => "#{action.capitalize} #{CONTROLLER.titleize}", :controller => CONTROLLER, :action => action)
      dba_role.rights << right
      competition_role.rights << right
    end

    dba_role.save
    competition_role.save
  end

  def self.down
    ACTIONS.each do |action|
      right = Right.find_by_name("#{action.capitalize} #{CONTROLLER.titleize}")
      Right.destroy(right.id)
    end
  end
end
