module Document
  module Fields::Embeds
    class Base

      include Mongoid::Document
      include ActsAsDefaultValue

    end
  end
end