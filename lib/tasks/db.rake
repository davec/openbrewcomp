namespace :db do
  desc 'Bootstrap the application'
  task :bootstrap => [ :environment, "db:migrate" ] do
    require 'active_record/fixtures'
    raise "Bootstrapping a non-empty database is not allowed" if CompetitionData.count > 0
    announce "Loading data"
    time = Benchmark.measure do
      fixture_dir = "#{RAILS_ROOT}/db/fixtures"
      all_fixtures = Dir.glob("#{fixture_dir}/*.yml").map { |f| File.basename(f, ".yml") }
      special_fixtures = %w(countries regions)
      mass_load_fixtures = all_fixtures - special_fixtures

      import = Import.new({})
      import.instance_variable_set(:@tables, mass_load_fixtures)
      import.instance_variable_set(:@files, mass_load_fixtures.map{|f| "${f}.yml"})
      fixtures_in_order = import.send(:determine_load_order)

      ActiveRecord::Base.connection.transaction do
        special_fixtures.each do |fixture|
          Fixtures.create_fixtures(fixture_dir, fixture)
        end
        Fixtures.create_fixtures(fixture_dir, fixtures_in_order)
      end
    end
    announce "Data loaded (%.4fs)" % time.real
  end

  def announce(message)
    length = [ 0, 75 - message.length ].max
    puts "==  %s %s" % [ message, '=' * length ]
  end
end
