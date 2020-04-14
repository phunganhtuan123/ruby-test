class ElasticSearch
  def self.bucket_size_settings
    @bucket_size_settings ||= $_CONFIG['system']['elasticsearch']['bulk_size']&.symbolize_keys || {}
  end

  def self.get_connector
    @connector ||= ElasticSearchConnector.new
  end
end

class ElasticSearchConnector
  def self.current_index
    $_PROD_ENV ? 'okiela_v1' : 'okiela'
  end

  ##
  # initialize will set up the connection
  def initialize
    connect if $_CONFIG['system']['elasticsearch']['enabled']
  end

  ##
  # create connection
  def connect
    unless defined?(@conn)
      @conn = Elasticsearch::Client.new(
        urls: $_CONFIG['system']['elasticsearch']['server'],
        reload_connections: true,
        retry_on_failure: 2,
        log: !$_PROD_ENV,
        logger: Logging::Elasticsearch.logger,
      )
    end

    @conn
  end

  ##
  # create a index
  # http://rubydoc.info/gems/elasticsearch-api/Elasticsearch/API/Indices/Actions#create-instance_method
  #
  # var index       string    [required] the name of the index which should get created
  # var settings    hash      [required] the settings for the index
  # @return         boolean
  def create_index(settings: nil)
    # return false if elasticsearch is disabled
    return false unless $_CONFIG['system']['elasticsearch']['enabled']

    index = ElasticSearchConnector.current_index

    # break if parameters not correct
    raise ArgumentError, "Parameters aren't correct." if
      !index.is_a?(String) || !settings.is_a?(Hash)

    # set the index
    @conn.indices.create(index: index, body: settings)
  end

  ##
  # delete a index
  # @return         boolean
  def delete_index
    # return false if elasticsearch is disabled
    return false unless $_CONFIG['system']['elasticsearch']['enabled']
    index = ElasticSearchConnector.current_index

    # set the index
    @conn.indices.delete(index: index)
  end

  ##
  # put mapping
  # http://rubydoc.info/gems/elasticsearch-api/Elasticsearch/API/Indices/Actions#put_mapping-instance_method
  #
  # var index       string    [required] the name of the index
  # var type        string    [required] the name of the type, e.g. product, user
  # var mapping     hash      [required] the mapping which has to be set for the defined type
  # @return         boolean
  def put_mapping(type: nil, mapping: nil)
    # return false if elasticsearch is disabled
    return false unless $_CONFIG['system']['elasticsearch']['enabled']
    index = ElasticSearchConnector.current_index

    # break if parameters not correct
    raise ArgumentError, "Parameters aren't correct." if
      !index.is_a?(String) || !type.is_a?(String) || !mapping.is_a?(Hash)

    # set the mapping
    @conn.indices.put_mapping(index: index, type: type, body: mapping)
  end

  # TODO: method document_exists method, using HEAD to check if a doc exists or not

  ##
  # get a specific document
  #
  # var index         string    [optional] index name, default is 'trendu'
  # var resource      object    [optional] the resource which should be fetched, the resource type defines the index type
  # var fields        array     [optional] array with fields to return from the doc, if nil the entire source will be returned
  # var resource_type string    [optional] if index type not defined by given resource, it is required as string here
  # var resource_id   int       [optional] if no resource object given the resource id is required here
  # @return           hash
  def get_document(resource: nil, fields: nil, resource_type: nil, resource_id: nil)
    # return nil if elasticsearch is disabled
    return nil unless $_CONFIG['system']['elasticsearch']['enabled']
    index = ElasticSearchConnector.current_index

    # set resource type name
    resource_type = Object.const_get(resource.class.list_class_name).resource_name if resource_type.nil?

    # load the document
    begin
      doc = @conn.get(
        index: index,
        type: resource_type,
        id: resource.is_a?(Backend::App::BaseResource) ? resource.id : resource_id,
        _source: fields.is_a?(Array) ? fields.join(',') : nil
      )
    rescue => e
      # if it is not a not found error, send an email to announce that the elasticsearch is not healthy
      unless e.is_a?(Elasticsearch::Transport::Transport::Errors::NotFound) || not_send_email?
        Backend::App::EmailHelper.send_plain_information(
          recipient: $_CONFIG['logging']['email']['address'],
          subject: "#{RACK_ENV} - ElasticSearch Error in get method",
          body: "#{YAML.dump(e)}\n\n#{YAML.dump($_ENV)}\n\n#{YAML.dump(e.backtrace)}"
        )
      end

      return nil
    end

    # return doc source
    doc['_source']
  end

  ##
  # get multiple specific document
  #
  # var index         string    [optional] index name, default is 'trendu'
  # var resource      object    [optional] the resource which should be fetched, the resource type defines the index type
  # var fields        array     [optional] array with fields to return from the doc, if nil the entire source will be returned
  # var resource_type string    [optional] if index type not defined by given resource, it is required as string here
  # var resource_id   int       [optional] if no resource object given the resource id is required here
  # @return           hash
  def mget_document(resource_type: nil, list_resource_id: nil, fields: nil)
    # return nil if elasticsearch is disabled
    return nil unless $_CONFIG['system']['elasticsearch']['enabled']
    index = ElasticSearchConnector.current_index

    # load the document
    begin
      doc = @conn.mget(index: index, type: resource_type, body: { ids: list_resource_id }, _source: fields)
    rescue => e
      puts e.message
    end

    # return doc source
    temp_docs = []
    doc['docs'].each do |one_doc|
      temp_docs << one_doc['_source']
    end unless doc.nil?
    temp_docs
  end

  ##
  # put a document
  # if the document is not existing yet, it will be created otherwise it will get updated
  #
  # var index         string    [optional] index name, default is 'trendu'
  # var resource      object    [optional] the resource which has to be indexed, the resource type defines the index type
  # var resource_type string    [optional] if index type not defined by given resource, it is required as string here
  # var resource_id   int       [optional] if no resource object given the resource id is required here
  # var body          object    [optional] hash object with the data to index, necessary if no resource object given
  # @return           boolean
  def put_document(resource: nil, resource_type: nil, resource_id: nil, body: nil, save_resource: true)
    # return false if elasticsearch is disabled
    return false unless $_CONFIG['system']['elasticsearch']['enabled']
    index = ElasticSearchConnector.current_index

    # set resource type name
    resource_type = Object.const_get(resource.class.list_class_name).resource_name if resource_type.nil?

    # set body
    body = resource.is_a?(Backend::App::BaseResource) ? resource.data(set: 'search_index') : body
    begin
      result = @conn.index(
        index: index,
        type: resource_type,
        id: resource.is_a?(Backend::App::BaseResource) ? resource.id : resource_id,
        body: body
      )
      if save_resource || resource.es_synced.zero? || resource.es_synced.nil?
        db = SequelDbConnection.get_connector
        db["res_#{resource_type}".to_sym].where(entity_id: resource.id).update(es_synced: 1)
      end
    rescue => e
      if resource.resync_on_fail?
        db = SequelDbConnection.get_connector
        db["res_#{resource_type}".to_sym].where(entity_id: resource.id).update(es_synced: 0)
      end

      # if it is not a not found error, send an email to announce that the elasticsearch is not healthy
      unless e.is_a?(Elasticsearch::Transport::Transport::Errors::NotFound) || not_send_email?
        Backend::App::EmailHelper.send_plain_information(
          recipient: $_CONFIG['logging']['email']['address'],
          subject: "#{RACK_ENV} - ElasticSearch Error in put method (#{resource.id})",
          body: "#{YAML.dump(e)}\n\n#{YAML.dump($_ENV)}\n\n#{YAML.dump(e.backtrace)}"
        )
      end

      return false
    end

    # convert given result to boolean and return
    result['ok'] == true
  end

  ##
  # Bulk index documents
  # if the document is not existing yet, it will be created otherwise it will get updated
  #
  # var index         string    [optional] index name, default is 'okiela'
  # var resources     object    [optional] the array of object, kind of BaseResource to bulk index
  # var resource_type string    [optional] if index type not defined by given resource, it is required as string here
  # @return           boolean
  def bulk(action: 'update', resources: nil, resource_type: nil)
    # return false if elasticsearch is disabled
    return false unless $_CONFIG['system']['elasticsearch']['enabled']

    raise "Invalid action: #{action}" unless %w[create update].include?(action)

    return if !resources.is_a?(Array) || resources.empty?

    raise "Resource must be an kind of Backend::App::BaseResource, but we found #{resources[0].class.name}" unless resources[0].is_a?(Backend::App::BaseResource)

    # set resource type name
    resource_type = Object.const_get(resources.first.class.list_class_name).resource_name if resource_type.nil?

    index = ElasticSearchConnector.current_index

    # set body
    processing_ids = []
    body = resources.map do |resource|
      processing_ids << resource.id.to_i
      data = { doc: resource.data(set: 'search_index') }

      { action.to_s => { '_index' => index,
                         '_type' => resource_type,
                         '_id' => resource.id,
                         'data' => data } }
    end

    begin
      result = @conn.bulk(body: body)
      # if action == "update"
      #   invalid_items = result["items"].select{|i| i[action]["status"] == 404 }.map{|i| i[action]["_id"] }.map(&:to_i)
      #   processing_ids = processing_ids - invalid_items
      # end
      update_all_params = { ids: processing_ids, hash_values: { es_synced: 1 } }

      if resource_type == 'product'
        Backend::App::Products.update_all(update_all_params)
      elsif resource_type == 'shop'
        Backend::App::Shops.update_all(update_all_params)
      elsif resource_type == 'order'
        Backend::App::Orders.update_all(update_all_params)
      elsif resource_type == 'user'
        Backend::App::Users.update_all(update_all_params)
      else
        raise "Not implemented bulk index for: #{resource_type}"
      end
    rescue => e
      # if it is not a not found error, send an email to announce that the elasticsearch is not healthy
      unless e.is_a?(Elasticsearch::Transport::Transport::Errors::NotFound) || not_send_email?
        Backend::App::EmailHelper.send_plain_information(
          recipient: $_CONFIG['logging']['email']['address'],
          subject: "#{RACK_ENV} - ElasticSearch Error in put BULK INDEX",
          body: "#{YAML.dump(e)}\n\n#{YAML.dump($_ENV)}\n\n#{YAML.dump(e.backtrace)}"
        )
      end

      return false
    end

    # convert given result to boolean and return
    result['ok'] == true
  end

  ##
  # delete a specific document
  #
  # var index         string    [optional] index name, default is 'trendu'
  # var resource      object    [optional] the resource which has to be deleted, the resource type defines the index type
  # var resource_type string    [optional] if index type not defined by given resource, it is required as string here
  # var resource_id   int       [optional] if no resource object given the resource id is required here
  # @return           boolean
  def delete_document(resource: nil, resource_type: nil, resource_id: nil)
    # return false if elasticsearch is disabled
    return false unless $_CONFIG['system']['elasticsearch']['enabled']
    index = ElasticSearchConnector.current_index

    # set resource type name
    resource_type = Object.const_get(resource.class.list_class_name).resource_name if resource_type.nil?

    begin
      result = @conn.delete(
        index: index,
        type: resource_type,
        id: resource.present? && resource.is_a?(Backend::App::BaseResource) ? resource.id : resource_id
      )
    rescue => e
      # if it is not a not found error, send an email to announce that the elasticsearch is not healthy
      unless e.is_a?(Elasticsearch::Transport::Transport::Errors::NotFound) || not_send_email?
        Backend::App::EmailHelper.send_plain_information(
          recipient: $_CONFIG['logging']['email']['address'],
          subject: "#{RACK_ENV} - ElasticSearch Error in delete method",
          body: "#{YAML.dump(e)}\n\n#{YAML.dump($_ENV)}\n\n#{YAML.dump(e.backtrace)}"
        )
      end

      return false
    end

    result['found']
  end

  ##
  # search
  #
  # var index       string    [optional] index name, default is 'trendu'
  # var type        string    [required] the name of the index type, e.g. product, user
  # var body        hash      [required] elasticsearch styled search body request
  # var fields      array     [optional] array with field names which should get returned for each hit
  def search(type: nil, body: nil, fields: nil)
    # return nil if elasticsearch is disabled
    return nil unless $_CONFIG['system']['elasticsearch']['enabled']
    index = ElasticSearchConnector.current_index

    begin
      # fire elastic search request
      @conn.search(index: index, type: type, body: body)
    rescue => e
      # if it is not a not found error, send an email to announce that the elasticsearch is not healthy

      params = $_REQUEST.present? ? $_REQUEST.params : {}
      Backend::App::FailoverServices::Elasticsearch.new(params).log_error(e)

      Backend::App::EmailHelper.send_plain_information(
        recipient: $_CONFIG['logging']['email']['address'],
        subject: "#{RACK_ENV} - ElasticSearch Error in search method",
        body: "#{YAML.dump(e)}\n\n#{YAML.dump($_ENV)}\n\n#{YAML.dump(e.backtrace)}"
      )

      raise e
    end
  end

  def count(type: nil, body: nil)
    return nil unless $_CONFIG['system']['elasticsearch']['enabled']
    return nil if type.nil?

    index = ElasticSearchConnector.current_index
    begin
      result = @conn.count(index: index, type: type, body: body)
    rescue Exception => e
      Backend::App::EmailHelper.send_plain_information(
        recipient: $_CONFIG['logging']['email']['address'],
        subject: "#{RACK_ENV} - ElasticSearch Error in count method",
        body: "#{YAML.dump(e)}\n\n#{YAML.dump($_ENV)}\n\n#{YAML.dump(e.backtrace)}"
      )
      return nil
    end

    result['count']
  end
end
