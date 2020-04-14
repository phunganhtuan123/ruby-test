require 'sequel'

class SequelDbConnection
  def self.get_connector(read_only: false)
    if read_only
      if !defined? @@connector_r
        @@connector_r = Sequel.connect( adapter: 'mysql2',
                                        host: $_CONFIG['database']['host_r'],
                                        port: $_CONFIG['database']['port_r'],
                                        username: $_CONFIG['database']['username'],
                                        password: $_CONFIG['database']['password'],
                                        database: $_CONFIG['database']['database'] #, max_connections: 6
                                      ) if !defined? @@connector_r
        @@connector_r.convert_tinyint_to_bool = false
        @@connector_r.loggers << Logging::Sequel.logger
      end
      return @@connector_r
    end

    if !defined? @@connector
      @@connector = Sequel.connect( adapter: 'mysql2',
                                    host: $_CONFIG['database']['host'],
                                    port: $_CONFIG['database']['port'],
                                    username: $_CONFIG['database']['username'],
                                    password: $_CONFIG['database']['password'],
                                    database: $_CONFIG['database']['database'] #, max_connections: 6
                                  ) if !defined? @@connector
      @@connector.convert_tinyint_to_bool = false
      @@connector.loggers << Logging::Sequel.logger
    end
    @@connector
  end
end
