# -*- coding: utf-8 -*-

module ContactsHelper

  Contact.roles.each do |role|
    %w(name email foo).each do |prop|
      define_method "#{role}_#{prop}".to_sym do
        @contacts[role][prop] || "Zombie #{role.titleize} #{prop.titleize}"
      end
    end
  end

end
