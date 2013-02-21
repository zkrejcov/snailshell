module SnailShell
    class Security

    @@_props = Settings.new

    def self.set_up_trusted(mailbox_label = nil, hash_key)
      mailbox_label = get_first_label unless mailbox_label
      if hash_key.empty? then
        @@_props.remove_security(mailbox_label)
      else
        @@_props.set_security({ "sig" => { mailbox_label => hash_key } })
      end
    end

    def self.show_trusted
      unless @@_props["security"]
        puts "No security settings were found."
      else
        puts "This daemon uses these signatures for hashing:"
        puts "<MAILBOX>".ljust(20)+"<SIGNATURE>"
        @@_props["security"]["sig"].each_pair { |key, value| puts "#{key}".ljust(20)+"#{value}" }
      end
    end

    # mailbox label
    def self.get_hash_key(mailbox = nil)
      if mailbox then
        @@_props["security"]["sig"][mailbox]
      else
        @@_props["security"]["sig"][get_first_label]
      end
    end

    def self.get_first_label
      @@_props["security"]["sig"].keys.first
    end
  end
end