# -*- coding: utf-8 -*-

class StylesController < ApplicationController

  def all
    unless fragment_exist?(:styles_all)
      @categories = Category.all(:conditions => [ 'is_public = ?', true ],
                                 :include => [ :awards, :styles ])
    end
  end

end
