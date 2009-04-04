# -*- coding: utf-8 -*-

class StylesController < ApplicationController

  def index
    @categories = Category.find(:all,
                                :conditions => [ 'is_public = ?', true ],
                                :include => [ :awards, :styles ])
  end

end
