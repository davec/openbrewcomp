class AddJudgeInvites < ActiveRecord::Migration

  def self.up
    dba_role = Role.find_by_name('Database Admin')
    registration_role = Role.find_by_name('Registration Admin')

    right = Right.create(:name => 'Send Judge Invites', :controller => 'judge_invites', :action => '*')
    dba_role.rights << right
    registration_role.rights << right

    dba_role.save
    registration_role.save
  end

  def self.down
    right = Right.find_by_name('Send Judge Invites')
    Right.destroy(right.id)
  end

end
