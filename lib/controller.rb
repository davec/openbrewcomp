# -*- coding: utf-8 -*-

# Utility module for the entrants/entries controllers/models, required
# to be able to properly configure the entry form depending on the
# context in which it is displayed (admin vs. non-admin and, in the
# admin case, nested vs. non-nested).
module Controller
  def self.method_missing(method, *args)
    set = method.to_s[-1,1] == '='
    name = method.to_s[/[^?=]*/].to_sym
    Thread.current[:hash] = {} unless Thread.current[:hash]
    if set
      Thread.current[:hash][name] = *args
    else
      Thread.current[:hash][name]
    end
  end
end
