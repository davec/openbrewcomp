# -*- coding: utf-8 -*-

class Admin::BoxCheckController < AdministrationController

  def index
    respond_to do |format|
      format.pdf do
        @categories = Category.all(:include => [ :awards, :styles ],
                                   :conditions => [ 'categories.is_public = ?', true ],
                                   :order => 'categories.position')
        render_pdf 'box_check.pdf', :preprocess => true
      end
    end
  end

end
