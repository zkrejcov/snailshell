require 'net/pop'
require 'open4'

module SnailShell
  class SnailshellDaemon
    include Utils

    @mailbox = MailboxProfiles.new.load_profile

    # checks only the first mailbox configured, the rest are ignored
    def self.run
      @out_log = File.open(Utils::DAEMON_LOG, 'w')
      @err_log = File.open(Utils::ERROR_LOG, 'w')
      @mail_log = File.open(Utils::MAIL_LOG, "w")
      trap(2) { on_exit }
      trap(9) { on_exit }
      trap(15) { on_exit }
      @out_log.sync= true
      @err_log.sync= true
      loop do
        check_mailbox(@mailbox)
        sleep(10)
      end
    end

    private

    def self.check_mailbox(mailbox)
      with_pop_session(mailbox) do |pop|
        unless pop.mails.empty?
          log "Found #{pop.mails.length} new message(s)."
          pop.each_mail do |mail|
            @mail = mail
            unless @mail.deleted? || !is_remote_control?
#              if is_remote_control?
              @mail_log.write @mail.pop
              @mail_log.puts
              process_mail
#              end
            end
          end
        else
          log "no new mail"
        end
      end
    rescue => exception
      log_exception exception, "Encountered a problem while checking the mailbox."
    end

    def self.with_pop_session(mailbox, &block)
      pop = Net::POP3.new(mailbox["host"], mailbox["port"]) # server, port
      pop.enable_ssl if mailbox["ssl"]=="y"
      pop.start(mailbox["account"], mailbox["password"]) { |pop| block.call(pop) } # acc, pwd
    end

    def self.process_mail
      body = get_body
      @subject = Utils::SUBJECT+" command ##{@mail.unique_id}"
      send_answer("Starting execution of command ##{@mail.unique_id}.")
      pid, stdin, stdout, stderr = Open4::popen4 body
      status = Process.wait2(pid)[1]
      send_answer compose_report(stdout, stderr, status)
      rescue => exception
        log_exception exception, "exec exception"
      ensure
        @mail.delete
        log "deleted"
    end

    def self.send_answer(answer)
      reply_to = ""
      @mail.header.each_line do |line|
        reply_to = line.sub("From: ", "").rstrip if line=~/From:/
      end
      SnailShell::Mail.send_answer(answer, EmailProfiles.new.get_label(reply_to), Security.get_first_label, @subject)
    end

    def self.compose_report(out, err, status)
      "================\nExecution Report\n================\n".upcase!+
      "---Output---\n".upcase!+
      "#{out.read.strip}\n"+
      "---Errors---\n".upcase!+
      "#{err.read.strip}\n"+
      "---Exit Status---\n".upcase!+
      "#{status}"
    end

    def self.is_remote_control?
      is_right_subject, is_right_hash = false, false
      @mail.header.each_line { |line| is_right_subject = true if line.rstrip==Utils::SUBJECT && !is_right_subject }
      is_right_hash = (Utils.count_hash(get_body, Security.get_hash_key()) == get_hash) if is_right_subject

      (is_right_subject && is_right_hash)
    end

    def self.get_body
      body = get_part(0).lines().to_a[0..-2].join.chomp("\n")

      body
    end

    def self.get_hash
      hash = get_part(1)
      hash = hash.lstrip.chomp(HASH_END).chomp("\n")

      hash
    end

    def self.get_part(part_no)
      part = @mail.all.lines(Utils::SUBJECT).to_a[1].lstrip.rstrip
      part = part.lines(HASH_START).to_a[part_no]

      part
    rescue => exception
      log_exception exception, "Encountered a problem while getting the mail body."
    end

    def self.log_exception(exception, message)
      log message, @err_log, @out_log
      log exception.inspect, @err_log
      log exception.backtrace.join("\n".ljust(28))+"\n", @err_log
    end

    def self.log(msg, stream = @out_log, opt_stream = nil)
      msg = Time.now.to_s+": "+msg
      stream.puts msg
      opt_stream.puts msg if opt_stream
    end

    def self.on_exit
      log "Exiting..."
        [@out_log, @err_log, @mail_log].each { |file| file.close }
      exit(0)
    end
  end
end