# -*- coding: utf-8 -*-

class Judging < ActiveRecord::Base
  belongs_to :judge
  belongs_to :flight

  ROLE_JUDGE = 'j'.freeze
  ROLE_STEWARD = 's'.freeze

end
