require 'clockwork'
module Clockwork
  handler do |job, time|
    puts "Running #{job}, at #{time}"
  end

  # every working day, every hour between 12pm and 6pm
  every(
    1.day,
    'metrics.send',
    at: (12..18).map{|h| "#{h}:00"},
    if: lambda { |t| !t.saturday? && !t.sunday? },
  ) { MetricsPublisher.new.publish! }
end
