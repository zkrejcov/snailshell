module SnailShell
  class EmailProfiles < Profiles

    def initialize
      keys = ["label", "host", "port", "domain", "ssl", "account", "password"]
      questions = ["Label for the email profile: ", "SMTP address: ", "Port: ", "Domain: ",
       "Enable ssl? y/N: ", "Account: ", "Password: "]
      super("email", keys, questions)
    end

    def show_profiles
      unless @_props["email"]
        puts "No email profiles found."
      else
        puts "\nThese email profiles are ready for use:\n\n"
        @_props["email"].each_pair do |key, value|
          puts "Label: #{key}"
          puts "SMTP address: #{value["host"]}"
          puts "Port: #{value["port"]}"
          puts "Domain: #{value["domain"]}"
          puts "SSL enabled: #{value["ssl"]}"
          puts "Account: #{value["account"]}"
          puts "Password: #{value["password"]}"
          puts
        end
      end
    end

    def get_label(address)
      @_props["email"].each_pair do |key, value|
        return key if value["account"]==address
      end
    end
  end
end