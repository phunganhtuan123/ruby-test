require_relative 'template'
require 'mail'

class Email

  ##
  # send mail method using mail gem
  #
  # @var account    string        [optional] defines which smtp account should be used, falls back to developer@okiela.com
  # @var from       string        [required] from information, e.g. support@okiela.com
  # @var to         string        [required] email address which should get this email
  # @var cc         string        [optional] email address used for email carbon copy
  # @var bcc        string        [optional] email address used for email blind carbon copy
  # @var subject    string        [required] email subject
  # @var body       string        [required] email body
  # @var attachment string        [optional] path to attachment
  def self.send_mail(account: 'support@okiela.com', from: nil, to: nil, cc: nil, bcc: nil, subject: nil, body: nil, attachment: nil, html_content: nil)
    # parameter check
    raise ArgumentError, "Email: 'from' information is missing." if from.nil?
    raise ArgumentError, "Email: 'to' information is missing." if to.nil?
    raise ArgumentError, "Email: 'subject' information is missing." if subject.nil?
    raise ArgumentError, "Email: 'body' information is missing." if body.nil?
    raise ArgumentError, "Email: 'account' is unknown" unless
      %w[awsdeveloper@okiela.com support@okiela.com developer@okiela.com trigger@okiela.com].include?(account)

    raise CustomError.new(
      status: 403,
      message: "Email không được hỗ trợ"
    ) if $_STAG_ENV && !Backend::App::AnalyticsHelper.development_email_whitelist.include?(to)

    # create mail
    mail = Mail.new do
      to to
      cc cc
      bcc bcc
      from from
      subject subject
      body body
      add_file filename: attachment.split('/').last, content: File.read(attachment) unless attachment.nil?
      content_type 'text/html; charset=UTF-8' unless html_content.nil?
    end

    account = 'developer@okiela.com' if $_CONFIG['email'][account].nil?

    # set delivery method information
    mail.delivery_method :smtp, {
      :address => $_CONFIG['email'][account]['host'],
      :port => $_CONFIG['email'][account]['port'],
      :domain => $_CONFIG['email'][account]['domain'],
      :user_name => $_CONFIG['email'][account]['user'],
      :password => $_CONFIG['email'][account]['password'],
      # :authentication => 'plain',
      :authentication => 'login',
      :enable_starttls_auto => true
    }

    # number of tries to send the mail
    tries = 3

    # catch errors if sending is impossible
    begin
      # send mail
      mail.deliver!
    rescue => e
      # reduce tries counter
      tries -= 1

      # check for left retires
      if tries > 0
        # wait 3 seconds
        sleep(3)

        # retry but
        retry
      else
        # disable email error
        # raise error
        # raise CustomError.new(
        #   status: 500,
        #   message: "E-Mail couldn't be send.\n\nsubject: #{subject}\nto: #{to}\nbody: #{body}, error: #{e.message}"
        # )
      end
    end
  end

  ##
  # validate email address syntax
  def self.validate(address)
    mail_regexp = %r{\A[^@]+@([^@\.]+\.)+[^@\.]+\z}
    if address.is_a?(Array)
      address.each do |val|
        raise "invalid email address `#{val.to_s}'" unless mail_regexp.match(val.to_s)
      end
    else
      raise "invalid email address `#{address.to_s}'" unless mail_regexp.match(address.to_s)
    end

    # return true
    true
  end
end

class EmailTemplate < Template
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
    parse
    @headers
  end

  def subject
    subject = nil
    headers.each do |item|
      matched = item.match(/^\s*subject\s*:\s*(.+?)\s*$/i)
      subject = matched[1] if matched
    end
    subject
  end

  def from
    subject = nil
    headers.each do |item|
      matched = item.match(/^\s*from\s*:\s*(.+?)\s*$/i)
      subject = matched[1] if matched
    end

    subject
  end

  def to
    subject = nil
    headers.each do |item|
      matched = item.match(/^\s*to\s*:\s*(.+?)\s*$/i)
      subject = matched[1] if matched
    end

    subject
  end
end
