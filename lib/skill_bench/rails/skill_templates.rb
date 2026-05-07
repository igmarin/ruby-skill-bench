# frozen_string_literal: true

require 'active_support/inflector'

module SkillBench
  module Rails
    # Generates Rails-specific skill templates
    class SkillTemplates
      # Generate a service object template
      # @param name [String] Service name (e.g., 'my_service' or 'my-service')
      # @return [String] Service object Ruby class
      def self.service_object(name)
        class_name = name.split(/[-_]/).map(&:capitalize).join
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
        module_name = name.camelize
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
        class_name = name.camelize
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
