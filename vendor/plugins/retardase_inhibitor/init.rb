require 'retardase_inhibitor'

ActionController::Base.send(:include, UrlWriterRetardaseInhibitor::ActionController)
ActionMailer::Base.send(:include, UrlWriterRetardaseInhibitor::ActionMailer)
