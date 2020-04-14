class DatabasePool
  def self.get_connector(read_only: false)
    if read_only
      if !defined? @@connector_r
        @@connector_r = DatabaseConnector.new(read_only: read_only)
      end

      return @@connector_r
    end

    if !defined? @@connector
      @@connector = DatabaseConnector.new
    end

    return @@connector
  end
end

class DatabaseConnector
  def initialize(read_only: false)
    connect(read_only: read_only)
  end

  ##
  # create connection to database
  def connect(read_only: false)
    unless defined?(@conn)
      @conn = Mysql2::Client.new(
        host: $_CONFIG['database'][(read_only ? 'host_r' :'host')],
        username: $_CONFIG['database']['username'],
        password: $_CONFIG['database']['password'],
        database: $_CONFIG['database']['database'],
        port: $_CONFIG['database'][(read_only ? 'port_r' : 'port')],
        socket: $_CONFIG['database']['socket'],
        encoding: $_CONFIG['database']['encoding'],
        read_timeout: $_CONFIG['database']['read_timeout'],
        write_timeout: $_CONFIG['database']['write_timeout'],
        as: :hash,
        symbolize_keys: true,
        reconnect: true
      )
    end
  end

  def connnection
    @conn
  end

  def affected_rows
    @conn.affected_rows
  end

  ##
  # converts value to string and returns escaped version
  def escape(val)
    return @conn.escape(val.to_s)
  end

  ##
  # executes an insert or update query.
  def execute(query: nil)
    # prepare query
    query = prepare_query(query)
    Logging::DatabasePool.logger.measure_info query do
      @conn.query(query)
    end
  end

  def query(sql: nil)
    execute(query: sql)
  end

  ##
  # returns the sql results single value, use it for queries with only one value as result
  def get_single_val(query: nil)
    # prepare and perform the query
    query = self.prepare_query(query)
    result = @conn.query(query)

    return nil unless result && result.count
    return nil if result.none?

    return result.first.first[1]
  end

  ##
  # takes an object as array, hash or string and will return the object as string.
  def prepare_query(query)
    raise "No query obtained." if query.nil?

    if query.respond_to?(:join)
      query = query.join(' ').strip
    end

    return query
  end

  ##
  # returns the "found rows" result of the most recent select query with SQL_CALC_FOUND_ROWS
  def get_found_rows
    begin
      result = @conn.query('SELECT FOUND_ROWS()', :as => :array)
    rescue => e
      return nil
    end

    return result.to_a[0][0]
  end

  ##
  # returns the mysql "last insert id"
  def last_id
    return @conn.last_id
  end

  ##
  # executes transaction.
  def open_transaction
    @conn.query('begin')
  end

  ##
  # executes transaction.
  def commit_transaction
    @conn.query('commit')
  end

  ##
  # executes transaction.
  def rollback_transaction
    @conn.query('rollback')
  end
end
