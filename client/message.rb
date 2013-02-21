require 'net/smtp'

module SnailShell
  HASH_START = "-----MAC BEGIN-----"
  HASH_END = "-----MAC END-----"
  class Message

    def self.send_over_smtp(from_host, from_port, from_ssl, from_domain, from_password, from_email, to, msg, subject = Utils::SUBJECT, hash)
      session = Net::SMTP.new(from_host, from_port) #addr, port
      session.enable_ssl if from_ssl
      session.start(from_domain, from_email, from_password, :login) do |smtp| #domain, acc, pwd, auth type
        smtp.send_message(compose(from_email, to, msg, subject, hash), from_email, to) #msg, from, to
      end
    end

    def self.compose(from, to, msg, subject, hash)
      message = "From: #{from}\n"
      message << "To: #{to}\n"
      message << "#{subject}\n\n"
      message << msg
      message << "\n"+HASH_START+"\n"
      message << hash
      message << "\n"+HASH_END

      message
    end
  end
end
