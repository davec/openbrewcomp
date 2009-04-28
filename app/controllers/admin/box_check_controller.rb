# -*- coding: utf-8 -*-

class Admin::BoxCheckController < AdministrationController

  def index
    respond_to do |format|
      format.pdf do
        @categories = Category.all(:include => [ :awards, :styles ],
                                   :conditions => [ 'categories.is_public = ?', true ],
                                   :order => 'categories.position')
        options_for_rtex = { :preprocess => true, :filename => "box_check.pdf" }
        options_for_rtex.merge({ :debug => true, :shell_redirect => "> #{File.expand_path(RAILS_ROOT)}/tmp/box_check.rtex.log 2>&1" }) if ENV['RAILS_ENV'] == 'development'
        render options_for_rtex.merge(:layout => false)
      end
    end
  end

end
