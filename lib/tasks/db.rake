namespace :db do
  desc 'Bootstrap the application'
  task :bootstrap => [ :environment, "db:migrate" ] do
    require 'active_record/fixtures'
    raise "Bootstrapping a non-empty database is not allowed" if CompetitionData.count > 0
    announce "Loading data"
    time = Benchmark.measure do
      Dir.glob("#{RAILS_ROOT}/db/fixtures/*.yml").sort.each do |file|
         Fixtures.create_fixtures('db/fixtures', File.basename(file, '.*'))
      end
    end
    announce "Data loaded (%.4fs)" % time.real
  end

  def announce(message)
    length = [ 0, 75 - message.length ].max
    puts "==  %s %s" % [ message, '=' * length ]
  end
end
