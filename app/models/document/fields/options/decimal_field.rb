module Document
  module Fields::Options
    class DecimalField < BaseOptions

      attribute :step, :decimal, default: 0.01

      validates :step,
                numericality: {
                  greater_than_or_equal_to: 0.0
                }

    end
  end
end
