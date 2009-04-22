# -*- coding: utf-8 -*-

class JudgeImport

  class ValidationError < StandardError; end

  attr_reader :errors, :warnings

  def initialize(file)
    @errors = Array.new
    @warnings = Array.new
    self.file_data = file['file_data']
  end

  def file_data=(file_data)
    @file_data = file_data
  end

  def valid?
    @basic_validity_check ||= begin
      unless @file_data.blank?
        # Check for a valid file. It should contain 12 tab-separated columns.
        begin
          @records = @file_data.read.split(/\r?\n|\r/)
          @errors << "#{@file_data.original_filename} is not a valid judges file" unless @records.length > 0 && @records[0].split("\t").length == 12
        rescue Exception => e
          @errors << "#{@file_data.original_filename} does not appear to be a valid judges file"
        end
      else
        @errors << "You must select a file to upload"
      end
      @errors.empty?
    end
    @basic_validity_check and @errors.empty?
  end

  # Process the file, one judge record at a time.
  def save
    return false unless @file_data && self.valid?
    @errors.clear

    # The BJCP judge list is a file of tab-separated records, with no column
    # header, containing the following columns (in order): first name, last
    # name, street address, city, state, zip code, country, phone number,
    # "goes by", email address, judge number, and judge rank.
    #
    # All fields are strings, so the country, state, and judge ranks must be
    # converted to their equivalent foreign key value.  This is currently done
    # on a literal basis.  This should not present a problem with the lists
    # supplied by the BJCP -- as long as the table of Judge Ranks is current --
    # but could be a problem for lists of non-BJCP judges if the Novice or
    # Experienced tags do not include the "(non-BJCP)" suffix.

    # TODO: We're not performing any checking for similar existing records,
    # instead the judges are simply added to the judges table. It would be a
    # good idea to try -- emphasis on try -- to detect duplicates.

    # The default for those cases where the BJCP list specifies an unrecognized
    # judge rank.
    fallback_bjcp_id = JudgeRank.find_by_description('N/A').id

    # The default rank for non-BJCP judges.
    fallback_non_bjcp_id = JudgeRank.find_by_description('Novice (non-BJCP)').id

    Judge.transaction do
      @records.each do |record|
        warnings = []
        @current_record = record
        fields = record.split("\t")
        country_id = Country.find_by_country_code(fields[6]).id
        region_id = Region.find_by_region_code_and_country_id(fields[4], country_id).id
        judge_number = fields[10]
        judge_rank_id = begin
                          JudgeRank.find_by_description(fields[11]).id
                        rescue
                          assigned_rank_id = judge_number.blank? ? fallback_non_bjcp_id : fallback_bjcp_id
                          warnings << "Unrecognized rank (set to #{JudgeRank.find(assigned_rank_id).description})"
                          assigned_rank_id
                        end
        email = if Authentication.email_regex.match(fields[9])
                  fields[9]
                else
                  warnings << 'Invalid email address (discarded)' unless fields[9].blank?
                  ''
                end
        begin
          Judge.create!(:first_name => fields[0],
                        :last_name => fields[1],
                        :address1 => fields[2],
                        :city => fields[3],
                        :region_id => region_id,
                        :postcode => fields[5],
                        :country_id => country_id,
                        :phone => fields[7],
                        :goes_by => fields[8],
                        :email => email,
                        :judge_number => judge_number,
                        :judge_rank_id => judge_rank_id,
                        :user_id => User.admin_id)
        rescue Exception => e
          @errors << %Q{#{e.to_s} in "#{@current_record}"}
        end
        @warnings << %Q{#{warnings.join(', ')} in "#{@current_record}"} unless warnings.empty?
      end
    end
    cleanup

    return @errors.empty? && @warnings.empty?
  end

  private

    def cleanup
      File.delete @file_data.path unless @file_data.path.nil? || ENV['RAILS_ENV'] == 'test'
    end

end
