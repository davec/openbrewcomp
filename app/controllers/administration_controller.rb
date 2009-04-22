# -*- coding: utf-8 -*-

class AdministrationController < ApplicationController

  layout "admin"

  before_filter :login_required

  rescue_from ActiveScaffold::RecordNotAllowed, :with => :access_denied

  ActiveScaffold.set_defaults do |config|
    config.theme = :blue
  end

  protected

    def authorized?(action = nil, resource = nil, *args)
      logged_in? && current_user.is_admin? && current_user.roles.detect{|role|
        role.rights.detect{|right|
          self.class.controller_path == 'admin/main' || self.class.controller_path == "admin/#{right.controller}"
        }
      }
    end

    def authorized_for?(obj)
      return false unless logged_in?
      user_id = if obj.is_a?(Integer)
                  obj
                elsif obj.respond_to?(:user_id)
                  obj.send(:user_id)
                end
      user_id && current_user.id == user_id
    end

end
