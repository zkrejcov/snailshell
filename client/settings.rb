module SnailShell
  class Settings
    include Utils

    def initialize
      @_props = {}
      @_props.merge!({ "email" => (get_settings_from_file Utils::EMAIL_SETTINGS) })
      @_props.merge!({ "mailbox" => (get_settings_from_file Utils::MAILBOX_SETTINGS) })
      @_props.merge!({ "security" => (get_settings_from_file Utils::SECURITY_SETTINGS) })
    end

    def [](key)
      @_props[key]
    end

    def set_email(props)
      set Utils::EMAIL_SETTINGS, props
    end

    def set_mailbox(props)
      set Utils::MAILBOX_SETTINGS, props
    end

    def set_security(props)
      set Utils::SECURITY_SETTINGS, props
    end

    def remove_email(label)
      remove Utils::EMAIL_SETTINGS, label
    end

    def remove_mailbox(label)
      remove Utils::MAILBOX_SETTINGS, label
    end

    def remove_security(label)
      setts = get_settings_from_file(Utils::SECURITY_SETTINGS)
      setts["sig"].delete(label)
      store_settings_to_file(setts, Utils::SECURITY_SETTINGS)
    end

    private
    def set(file, new_props = {})
      setts = get_settings_from_file(file)
      merged = deep_merge!(setts, new_props)
      store_settings_to_file(merged, file)
      initialize
    end

    def remove(file, label)
      setts = get_settings_from_file(file)
      setts.delete(label)
      store_settings_to_file(setts, file)
    end

    # merge changes from hash2 into hash1
    def deep_merge!(hash1, hash2)
      # replace existing setttings with new ones
      hash1.each_pair do |key, value|
        value.merge! hash2[key] if hash2.has_key? key
      end
      # add new ones, if there are any
      hash2.each_pair do |key, value|
        hash1[key] = value unless hash1.has_key? key
      end

      hash1
    end

    def get_settings_from_file(file)
      props = {}
      File.read(file).lines do |line|
        property = line.rstrip.split('=', 2)
        if property[0]=="label" then
          props[property[1]] = {}
        else
          key = property[0].split(".", 2)
          props[key[0]][key[1]]=property[1]
        end
      end

      props
    end

    def store_settings_to_file(props = {}, file)
      properties_string = ""
      props.each_pair do |key, value|
        properties_string << "label=#{key}\n"
        value.each_pair { |key2, value2| properties_string << "#{key}.#{key2}=#{value2}\n" }
      end
      File.open(file, "w") { |io| io << properties_string }
    end
  end
end