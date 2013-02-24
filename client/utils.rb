require "openssl"
require "openssl/digest"

module SnailShell
  module Utils
    MAILBOX_SETTINGS = "settings/mailbox_settings"
    SECURITY_SETTINGS = "settings/security_settings"
    EMAIL_SETTINGS = "settings/email_settings"
    SUBJECT = "Subject: [remote control]"
    TIMESTAMP = "VALID UNTIL:"
    DAEMON_LOG = "log/daemon.log"
    ERROR_LOG = "log/error.log"
    MAIL_LOG = "log/mail.log"
    DAEMON_PID = ".daemon"

    def Utils.count_hash(msg, key)
      sha1 = OpenSSL::Digest::SHA1.new
      digest = sha1.hexdigest(msg+"#{key}")

      digest
    end
  end
end
