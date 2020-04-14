##
# custom error class
class CustomError < RuntimeError
  attr_accessor :status, :message, :hint, :critical, :debug_message

  ##
  # if critical is set to true, it will send an email with a special flag for maximum attention
  def initialize(status: 500, message: nil, hint: nil, critical: false, debug_message: nil)
    @status = status
    @message = message
    @hint = hint
    @critical = critical
    @debug_message = debug_message
  end
end

##
# payment error class
class PaymentError < RuntimeError
  attr_accessor :status, :message, :hint, :critical, :debug_message

  ##
  # critical is set to true by default
  def initialize(status: 500, message: nil, hint: nil, debug_message: nil)
    @status = status
    @message = message
    @hint = hint
    @critical = true
    @debug_message = debug_message

    # TODO: the entire error and error notification handling has to be refactored and clear structed
    # TODO: all emails should be send in the error classes like here, not in the error() method in ctrl_base
    # send mail about this error if this happened not while api usage
    Email.send_mail(
      account: $_PROD_ENV ? 'support@okiela.com' : 'developer@okiela.com',
      from: $_PROD_ENV ? 'support@okiela.com' : 'developer@okiela.com',
      to: $_CONFIG['logging']['email']['address'],
      subject: "#{RACK_ENV} - Payment Provider Error",
      body: "#{@message}\n\n#{@debug_message}"
    ) if $_USER.nil?
  end
end

##
# payment error class
class MangoPayError < RuntimeError
  attr_accessor :status, :message, :hint, :critical, :debug_message

  ##
  # critical is set to true by default
  def initialize(message)
    @status = 500
    @message = message
    @critical = true
  end
end
