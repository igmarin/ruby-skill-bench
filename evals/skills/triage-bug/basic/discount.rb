# frozen_string_literal: true

class Discount
  def self.apply(cents:, percent:)
    cents / 100 * percent
  end
end
