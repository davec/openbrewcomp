# -*- coding: utf-8 -*-

class Admin::ImportsController < AdministrationController

  def import_db
    @import = Import.new(params[:archive])
    if @import.save
      flash[:notice] = 'Database import was successful'
      redirect_to admin_path
    else
      flash[:import_error] = messages(@import.errors, 'Database import failed')
      redirect_to admin_import_db_path
    end
  end

  def import_judges
    # HACK: Force the judge model to accept judge records that would be invalid
    # if entered by a non-admin user, e.g., missing street address, city, etc.
    Controller.admin_view = true

    @import = JudgeImport.new(params[:file])
    if @import.save
      flash[:notice] = 'Judge list import was successful'
      redirect_to admin_path
    else
      flash[:judge_import_errors] = messages(@import.errors, 'Errors importing judge list') unless @import.errors.empty?
      flash[:judge_import_warnings] = messages(@import.warnings, 'Warnings importing judge list') unless @import.warnings.empty?
      redirect_to admin_import_judges_path
    end
  end

  private

    BULLET = "\xe2\x80\xa2".freeze

    def messages(messages, message_prefix)
      if messages.empty?
        message_prefix
      elsif messages.length == 1
        "#{message_prefix}: #{messages[0]}"
      else
        [ "#{message_prefix}:" ] + messages.collect{|e| "#{BULLET} #{e}"}
      end
    end

end
