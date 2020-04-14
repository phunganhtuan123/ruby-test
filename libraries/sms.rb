require_relative 'template'
require 'uri'
require 'net/http'
require 'cgi'
require 'fileutils'

class Sms

  SMS_UNIT_LENGTH = 160
  ##
  # send sms message method
  #
  # @var account      string        [optional] defines which sms account should be used
  # @var from         string        [required] from information, e.g. support@okiela.com
  # @var to           string        [required] phone number which should get this message
  # @var message      string        [required] sms message
  # @var retry_count  int           [optional] defines how many times need to retry
  def self.send_message(account: 'TGPM', from: nil, to: nil, message: nil, retry_count: 0, type: nil, obj: nil)
    return nil unless $_CONFIG['sms']['enabled'].boolean_true?

    # parameter check
    raise ArgumentError, "SMS: 'from' information is missing." if from.nil?
    raise ArgumentError, "SMS: 'to' information is missing." if to.nil?
    raise ArgumentError, "SMS: 'message' information is missing." if message.nil?
    raise ArgumentError, "SMS: 'account' is unknown" unless %w[OkieLa TGPM].include?(account)

    if $_STAG_ENV && !Backend::App::AnalyticsHelper.development_phone_whitelist.include?(to)
      raise CustomError.new(
        status: 403,
        message: 'Số điện thoại không được hỗ trợ'
      )
    end

    tries = retry_count

    begin
      message = CGI.escape(message)

      username = $_CONFIG['sms']['username']
      password = $_CONFIG['sms']['password']

      # send message
      client = "http://cloudsms.vietguys.biz:8088/api/?u=#{username}&pwd=#{password}&from=#{from}&phone=#{to}&sms=#{message}"
      response = Net::HTTP.get(URI.parse(client))

      current_month = Time.now.strftime('%Y_%m')
      increase_counter(message_length: message.length, month: current_month)

      if response.to_i < 0
        tries -= 1

        if tries > 0
          sleep(3)

          send_message(account: account, from: from, to: to, message: message, retry_count: tries)

        else
          raise CustomError.new(
            status: 500,
            message: "Message couldn't be send.\n\nmessage: #{message}\nfrom: #{from}\nto: #{to}\nerror: #{response}"
          )
        end
      else
        increase_counter(message_length: message.length, month: current_month, success: true)
        increase_counter_in_file(month: current_month)
      end
    rescue Exception => e
      Backend::App::EmailHelper.send_plain_information(
        recipient: $_CONFIG['logging']['email']['address'],
        subject: "#{RACK_ENV} -Sms service error.",
        body: e.message + "\n" + e.backtrace.join("\n")
      )
    end
  end

  def self.increase_counter(message_length: 0, month: nil, success: false)
    return unless message_length.positive?

    key = month || Time.now.strftime('%Y_%m')
    credit = message_length / SMS_UNIT_LENGTH + ((message_length % SMS_UNIT_LENGTH) > 0 ? 1 : 0)
    sms_counter_hash = Backend::App::CacheManager.get(namespace: Backend::App::CacheManager::CACHE_NAME_SPACE[:sms_counter], key: key) || sms_counter_template
    sms_counter_hash[:total_sent] = sms_counter_hash[:total_sent] + 1
    sms_counter_hash[:credit_sent] = sms_counter_hash[:credit_sent] + credit
    if success
      sms_counter_hash[:total_delivered] = sms_counter_hash[:total_delivered] + 1
      sms_counter_hash[:credit_delivered] = sms_counter_hash[:credit_delivered] + credit
    end

    Backend::App::CacheManager.delete(namespace: Backend::App::CacheManager::CACHE_NAME_SPACE[:sms_counter], key: key)
    Backend::App::CacheManager.fetch(Backend::App::CacheManager::CACHE_NAME_SPACE[:sms_counter], key) do
      sms_counter_hash
    end
  end

  def self.sms_counter_template
    {
      total_sent: 0,
      credit_sent: 0,
      total_delivered: 0,
      credit_delivered: 0
    }
  end

  def self.increase_counter_in_file(month: nil)
    file_name = month || Time.now.strftime('%Y_%m')
    file_path = [$_CONFIG['system']['files']['sms_counters'], file_name].join('/')

    current_count = Backend::App::Utility.read_file(file_path).to_i
    current_count += 1
    Backend::App::Utility.write_file(current_count, file_path).to_i
  end

  def self.change_to_validate_phone_format(phone_param)
    phone = phone_param.gsub(/\s+/, '')

    # we allow 10 or 11 numbers in VietNam
    # ten_numbers = /^[0][9]\(?([0-9]{1})\)?([0-9]{3})([0-9]{4})$/
    # eleven_numbers = /^[0][1]\(?([0-9]{2})\)?([0-9]{3})([0-9]{4})$/
    country_code_ten_numbers = /^[+]?[8][4][9]\(?([0-9]{1})\)?([0-9]{3})([0-9]{4})$/
    country_code_eleven_numbers = /^[+]?[8][4][1]\(?([0-9]{2})\)?([0-9]{3})([0-9]{4})$/

    return phone unless country_code_ten_numbers.match(phone.to_s) || country_code_eleven_numbers.match(phone.to_s)

    phone.sub!(%r{^+84}, '0')
  end
end

class SmsTemplate < Template
  def initialize(template: '', marker: ':::', values: {})
    super(template: template, marker: marker, values: values)

    @headers = []
    @parsed_wo_headers = nil
  end

  def parse(force: false)
    return @parsed_wo_headers unless @parsed_wo_headers.nil? || force

    parent_parsed = super(force: force)

    @headers = []
    @parsed_wo_headers = ''
    # try to split headers from body
    header_end = false
    parent_parsed.each_line do |l|
      if header_end
        @parsed_wo_headers << l
      elsif m = l.match(/^\s*$/)
        header_end = true
      elsif m = l.match(/^\s*([-_a-z0-9.]+)\s*:\s*(.+?)\s*$/i)
        @headers.push(l.chomp())
      else
        header_end = true
        @parsed_wo_headers << l
      end
    end

    return @parsed_wo_headers
  end

  def headers
    parse()
    @headers
  end

  def message
    message = nil
    headers().each do |item|
      if m = item.match(/^\s*message\s*:\s*(.+?)\s*$/i)
        message = m[1]
      end
    end

    return message
  end

  def from
    subject = nil
    headers().each do |item|
      if m = item.match(/^\s*from\s*:\s*(.+?)\s*$/i)
        subject = m[1]
      end
    end

    return subject
  end
end
