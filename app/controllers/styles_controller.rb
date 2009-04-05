# -*- coding: utf-8 -*-

class StylesController < ApplicationController

  def index
    unless fragment_exist?(:styles_index)
      @categories = Category.find(:all,
                                  :conditions => [ 'is_public = ?', true ],
                                  :include => [ :awards, :styles ])
    end
  end

end
