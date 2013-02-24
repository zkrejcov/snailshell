require 'net/smtp'

module SnailShell
  class Mail
    include Utils

    @email = EmailProfiles.new
    @mailbox = MailboxProfiles.new

    def self.send_mail(command = nil, label = nil, sender = nil)
      load_info(command, label, sender)
      valid_until = ask("Add VALID UNTIL timestamp? Enter in format yyyy-[m]m-[d]d [h]h:[m]m:[s]s or leave blank for no timestamp: ")
      send_over_smtp(@email["account"], @mailbox["account"], @msg, get_time(valid_until))
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

    def self.send_over_smtp(from, to, msg, subject = Utils::SUBJECT, valid_until = nil)
      unless File.exists? msg
        message = msg
      else
        message = File.read(msg).chomp
      end

      message = Utils::TIMESTAMP + valid_until.to_i + "\n" + message if valid_until
      hash = Utils.count_hash(message, Security.get_hash_key(@label))

      Message.send_over_smtp(@email["host"], @email["port"], (@email["ssl"] == "y"),
        @email["domain"], @email["password"], from, to, message, subject, hash)
    end

    def self.get_time(user_input)
      return nil if !user_intput or user_input.is_empty

      date_time = user_input.split(" ")
      date_parts = date_time[0].split("-")
      time_parts = date_time.split(":")

      Time.new(date_parts[0].to_i,date_parts[1],date_parts[2].to_i,time_parts[0].to_i,time_parts[1].to_i,time_parts[2].to_i)
    end

    def self.ask(question)
      print question

      gets.rstrip
    end
  end
end
