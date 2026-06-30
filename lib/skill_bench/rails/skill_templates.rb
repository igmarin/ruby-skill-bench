# frozen_string_literal: true

module SkillBench
  module Rails
    # Generates Rails-specific skill templates
    class SkillTemplates
      # Convert a snake_case or kebab-case name to CamelCase.
      #
      # Replaces ActiveSupport's +String#camelize+ for the scaffold inputs used
      # here: it splits on +_+ and +-+ separators, upcases the first letter of
      # each segment, and preserves any segment that is already CamelCase.
      #
      # @example
      #   SkillTemplates.camelize('user_creator') # => "UserCreator"
      #   SkillTemplates.camelize('order-service') # => "OrderService"
      #   SkillTemplates.camelize('UserCreator')   # => "UserCreator"
      # @param name [String] snake_case, kebab-case, or already-CamelCase name
      # @return [String] CamelCase name
      def self.camelize(name)
        name.split(/[-_]/).map { |segment| segment.empty? ? segment : segment[0].upcase + segment[1..] }.join
      end

      # Generate a service object template
      # @param name [String] Service name (e.g., 'my_service' or 'my-service')
      # @return [String] Service object Ruby class
      def self.service_object(name)
        class_name = camelize(name)
        <<~RUBY
          # frozen_string_literal: true

          module SkillBench
            module Skills
              class #{class_name}
                # Initialize with required parameters
                # @param args [Hash] Keyword arguments for the service
                def initialize(**args)
                  # Set instance variables from args
                end

                # Execute the service
                # @return [Hash] Result with :success and :response keys
                def call
                  # Implement service logic here
                  { success: true, response: { message: 'Not implemented' } }
                rescue StandardError => e
                  Rails.logger.error(e.message)
                  Rails.logger.error(e.backtrace.first(5).join("\n"))
                  { success: false, response: { error: { message: e.message } } }
                end
              end
            end
          end
        RUBY
      end

      # Generate a concern template
      # @param name [String] Concern name (e.g., 'my_concern')
      # @return [String] Concern module
      def self.concern(name)
        module_name = camelize(name)
        <<~RUBY
          # frozen_string_literal: true

          module #{module_name}
            extend ActiveSupport::Concern

            included do
              # Add class methods, associations, validations here
            end

            class_methods do
              # Add class methods here
            end

            # Add instance methods here
          end
        RUBY
      end

      # Generate an ActiveRecord model template
      # @param name [String] Model name (e.g., 'my_model')
      # @return [String] ActiveRecord model class
      def self.active_record_model(name)
        class_name = camelize(name)
        <<~RUBY
          # frozen_string_literal: true

          class #{class_name} < ApplicationRecord
            # Validations
            validates :name, presence: true

            # Associations
            # belongs_to :user
            # has_many :items

            # Scopes
            # scope :active, -> { where(active: true) }

            # Instance methods
            # def some_method
            #   ...
            # end

            # Class methods
            # def self.some_class_method
            #   ...
            # end
          end
        RUBY
      end
    end
  end
end
