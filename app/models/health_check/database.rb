module HealthCheck
  class Database < Component
    def accessible?
      begin
        tuple = execute_simple_select_on_database
        result = tuple.to_a == [{ 'result' => '1' }]
      rescue => e
        log_unknown_error(e)
        result = false
      end
      result
    end

    def available?
      begin
        result = ActiveRecord::Base.connected?
        log_error unless result == true
      rescue => e
        log_unknown_error(e)
        result = false
      end
      result
    end

  private

    def execute_simple_select_on_database
      ActiveRecord::Base.connection.execute('select 1 as result')
    end

    def log_error
      @errors = ["Database Error: could not connect with #{config}"]
    end

    def config
      full_config = Rails.configuration.database_configuration[Rails.env]
      permitted_keys = %w[ url database host adapter ]
      filtered_config = full_config.slice(*permitted_keys)
      filtered_config.sort.map { |k, v| "#{k}='#{v}'" }.join(' ')
    end
  end
end
