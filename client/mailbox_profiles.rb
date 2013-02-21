module SnailShell
    class MailboxProfiles < Profiles

    def initialize
      keys = ["label", "host", "port", "ssl", "account", "password"]
      questions = ["Label for the mailbox: ", "POP address: ", "Port: ", "Enable ssl? y/N: ",
        "Account: ", "Password: "]
      super("mailbox", keys, questions)
    end

    def show_profiles
      unless @_props["mailbox"]
        puts "No mailbox settings found."
      else
        puts "\nCurrently watched mailboxes:\n\n"
        @_props["mailbox"].each_pair do |key, value|
          puts "Label: #{key}"
          puts "POP address: #{value["host"]}"
          puts "Port: #{value["port"]}"
          puts "SSL enabled: #{value["ssl"]}"
          puts "Account: #{value["account"]}"
          puts "Password: #{value["password"]}"
          puts
        end
      end
    end
  end
end