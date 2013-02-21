module SnailShell
  class Profiles

    def initialize(type, profile_keys, profile_questions)
      @_props = Settings.new
      @type, @profile_keys, @profile_questions = type, profile_keys, profile_questions
    end

    def load_profile(label = nil)
      @label = label
      @profile = label ? @_props[@type][label] : @_props[@type][@_props[@type].keys.first]

      self
    end

    def [](key)
      @profile[key]
    end

    def add_profile
      props = {}
      @profile_questions.each { |q| props.store(@profile_keys.shift, get_setting(q)) }
      label = props.delete("label")
      case @type
      when "email"
        @_props.set_email({ label => props })
      when "mailbox"
        @_props.set_mailbox({ label => props })
      end
      self.load_profile(label)
    end

    def remove_profile(label)
      case @type
      when "email"
        @_props.remove_email(label)
      when "mailbox"
        @_props.remove_mailbox(label)
      end
    end

    private
    def get_setting(question)
      print question

      gets.rstrip
    end
  end
end