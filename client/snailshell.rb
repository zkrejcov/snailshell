#!/usr/bin/env ruby

require 'optparse'
require_relative 'utils'
require_relative 'settings'
require_relative 'profiles'
require_relative 'mailbox_profiles'
require_relative 'snailshell_daemon'
require_relative 'email_profiles'
require_relative 'mail'
require_relative 'security'
require_relative 'message'

include SnailShell::Utils

def run_daemon
  pid = fork {SnailShell::SnailshellDaemon.run}
  puts pid
  File.open(SnailShell::Utils::DAEMON_PID, 'a') { |file| file.puts pid }
  Process.detach pid
end

def kill_daemons
  File.open(SnailShell::Utils::DAEMON_PID, 'r') do |file|
    file.each_line do |line|
      pid = line.chop
      begin
        puts `kill #{pid}`
      rescue => exception
        puts exception
        puts exception.backtrace
      end
    end
  end
  File.delete(SnailShell::Utils::DAEMON_PID)
end

# parse commandline options
OptionParser.new do |opts|
  opts.banner = "Usage: main.rb [option [value[,value]]]

Settings can be also configured by directly editing the appropriate file in settings/ folder.
Please, keep the order as it is, if you do so. Append new settings to the end of the file.
  "

  opts.on("-d", "--daemon", "run the daemon") do
    puts "Starting the daemon in the background."
    run_daemon
  end

  opts.on("-D", "--kill-daemons", "kill all the snailshell daemons running") do
    puts "Killing all daemons."
    kill_daemons
  end

  opts.on("-m", "--send-mail", "send email to preconfigured mailbox
                                     from preconfigured address") do
    puts "About to send email..."
    SnailShell::Mail.send_mail
  end

  opts.on("-c CMD,TO,FROM", "--command CMD,TO,FROM", Array, "send a predefined command CMD
                                     to a mailbox profile TO from email profile FROM") do |arg|
    puts "Sending command '#{arg[0]}' to '#{arg[1]}' from '#{arg[2]}'."
    SnailShell::Mail.send_mail arg[0], arg[1], arg[2]
  end

  opts.on("-T [LABEL]", "--trust-all [LABEL]", "allow control to anyone (on a LABELed mailbox profile)") do |label|
    unless label then
      puts "This machine will now accept commands from anyone."
    else
      puts "SnailShell won't be using a signature for outgoing commands to '#{label}'."
    end
    SnailShell::Security.set_up_trusted(label, "")
  end

  opts.on("-t SIGNATURE,[LABEL]", "--trust SIGNATURE,[LABEL]", Array, "set the SIGNATURE to trust") do |arg|
    unless arg[1] then
      puts "This machine now only accepts commands with the provided signature."
    else
      puts "Setting up signature for mailbox labelled as '#{arg[1]}'"
    end
    SnailShell::Security.set_up_trusted(arg[1], arg[0])
  end

  opts.on("-S", "--show-trusted", "prints the trusted signature, if there is some set") do
    SnailShell::Security.show_trusted
  end

  opts.on("-s", "--set-mailbox", "run program in set-mailbox mode,
                                     allowing you to set the mailbox to watch") do
    puts "About to add a new mailbox to watch (if it is the first one set) or send commands to..."
    SnailShell::MailboxProfiles.new.add_profile
  end

  opts.on("-r LABEL", "--remove-mailbox LABEL", "remove a watched mailbox") do |label|
    puts "Removing mailbox profile labelled as '#{label}'."
    SnailShell::MailboxProfiles.new.remove_profile label
  end

  opts.on("-l", "--list-mailboxes", "show watched mailboxes") do
    SnailShell::MailboxProfiles.new.show_profiles
  end

  opts.on("-e", "--set-profile", "run program in set-email-profile mode, allowing
                                     you to set the email profile to send commands from") do
    puts "About to add a new email profile to send commands from..."
    SnailShell::EmailProfiles.new.add_profile
  end

  opts.on("-E LABEL", "--remove-profile LABEL", "remove a profile") do |label|
    puts "Removing email profile labelled as '#{label}'"
    SnailShell::EmailProfiles.new.remove_profile label
  end

  opts.on("-p", "--list-profiles", "show configured email profiles") do
    SnailShell::EmailProfiles.new.show_profiles
  end

end.parse!
