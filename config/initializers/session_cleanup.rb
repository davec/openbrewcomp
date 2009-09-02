# Be sure to restart your web server when you modify this file.

class SessionCleanup
  def self.purge_expired_sessions
    ActiveRecord::SessionStore::Session.destroy_all(
      [ 'updated_at < ?', 2.hours.ago ]
    )
  end
end
