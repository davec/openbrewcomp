# -*- coding: utf-8 -*-

module ActiveRecordPermissions::Permissions::ClassMethods
  # Patch authorized_for? to deal gracefully with singletons,
  # referencing self.instance if self.new raises a NoMethodError.
  def authorized_for?(*args)
    @authorized_for_delegatee ||= begin
                                    self.new
                                  rescue NoMethodError
                                    self.instance
                                  rescue Exception => e
                                    raise e
                                  end
    @authorized_for_delegatee.authorized_for?(*args)
  end
end
