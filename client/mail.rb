require 'net/smtp'

module SnailShell
  class Mail
    include Utils

    @email = EmailProfiles.new
    @mailbox = MailboxProfiles.new

    def self.send_mail(command = nil, label = nil, sender = nil)
      load_info(command, label, sender)
      send_over_smtp(@email["account"], @mailbox["account"], @msg)
    end

    def self.send_answer(answer, to_label, from_label, subject)
      @label = to_label
      @email.load_profile(from_label)
      @mailbox.load_profile @label
      send_over_smtp(@email["account"], @mailbox["account"], answer, subject)
    end

    private
    def self.load_info(command = nil, label = nil, sender = nil)
      sender = ask("Which email profile to use? ") unless sender
      @email.load_profile(sender)
      @label = label or ask("Which mailbox label to send to? ")
      @mailbox.load_profile @label
      unless command
        @msg = ask("Which file contains the message? You can press <enter> to type it manually: ")
        if @msg == "" then
          @msg = ask("Message is:")
        else
          raise("There is no such file (file #{@msg}).") unless File.exist? @msg
        end
        puts
      else
        @msg = 'commands/'+command
        raise("There is no such command registred (file #{@msg}).") unless File.exist? @msg
      end
    end

    def self.send_over_smtp(from, to, msg, subject = Utils::SUBJECT)
      unless File.exists? msg
        message = msg
      else
        message = File.read(msg).chomp
      end

      hash = Utils.count_hash(message, Security.get_hash_key(@label))

      Message.send_over_smtp(@email["host"], @email["port"], (@email["ssl"] == "y"),
        @email["domain"], @email["password"], from, to, message, subject, hash)
    end

    def self.ask(question)
      print question

      gets.rstrip
    end
  end
end