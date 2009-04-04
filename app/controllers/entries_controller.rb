# -*- coding: utf-8 -*-

class EntriesController < ApplicationController

  def index
    render :action => 'rules'
  end

end
