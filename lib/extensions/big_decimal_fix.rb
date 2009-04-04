# -*- coding: utf-8 -*-

class BigDecimal
  # this works around http://code.whytheluckystiff.net/syck/ticket/24 until it gets fixed.
  # (as found at http://blog.chrispcritter.com/articles/2007/02/11/bigdecimal-and-yaml-dont-get-along)
  alias :_original_to_yaml :to_yaml
  def to_yaml (opts={},&block)
    to_s.to_yaml(opts,&block)
  end
end
