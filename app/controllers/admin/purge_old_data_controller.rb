# -*- coding: utf-8 -*-

class Admin::PurgeOldDataController < AdministrationController

  def index
    @allowed = competition_data.is_data_purge_allowed?
    @competition_date = competition_data.competition_date.to_s(:long) rescue nil
  end

  def purge
    if request.post?
      # TODO: Get the tables from the posted params.
      # For now, use the hard-coded list in the model.
      victims = PurgeOldData.new
      if victims.valid?
        begin
          victims.zap
          flash[:notice] = 'Successfully purged old data'
          redirect_to admin_path and return
        rescue Exception => e
          errors = e.to_s
        end
      else
        error_prefix = 'Unable to purge old data'
        errors = if victims.errors.blank?
                   error_prefix
                 elsif victims.errors.length == 1
                   "#{error_prefix}: #{victims.errors[0]}"
                 else
                   # There shouldn't be more than one error, but just in case ...
                   bullet = "\xe2\x80\xa2"
                   [ "#{error_prefix}:" ] + victims.errors.collect{|e| "#{bullet} #{e}"}
                 end
      end
      flash[:error] = errors
      redirect_to purge_path
    end
  end

end
