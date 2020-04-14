module Enumerable
  # Simple parallel map using Celluloid::Futures
  def pmap(&block)
    futures = map { |elem| Celluloid::Future.new(elem, &block) }
    begin
      futures.map(&:value)
    rescue => e
      Backend::App::EmailHelper.send_plain_information(
        recipient: $_CONFIG['logging']['email']['address'],
        subject: "#{RACK_ENV} - error when use Celluloid pmap",
        body: "Exception: " + e.message + "\n" + e.backtrace.join("\n")
      )

      return []
    end
  end
end
