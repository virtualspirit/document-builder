require 'mail'

module Document
  module Concerns
    module Models
      module Fields
        module Validations
          module Email
            extend ActiveSupport::Concern

            included do
              embeds_one :email, class_name: "Document::Concerns::Models::Fields::Validations::Email::EmailOptions"
              accepts_nested_attributes_for :email

              after_initialize do
                build_email unless email
              end
            end

            def interpret_to(model, field_name, accessibility, options = {})
              super
              email&.interpret_to model, field_name, accessibility, options
            end

            class EmailOptions < Document::FieldOptions
              attribute :whitelist, :string, array: true, default: []
              attribute :blacklist, :string, array: true, default: []
              attribute :message, :string


              def interpret_to(model, field_name, _accessibility, _options = {})
                options = {}
                options[:whitelist] = whitelist
                options[:blacklist] = blacklist
                options[:message] = message
                options.symbolize_keys!

                model.validates_with EmailValidator, _merge_attributes([field_name, options])
              end

            end

            class EmailValidator < ActiveModel::EachValidator

              def default_options
                { blacklist: [], whitelist: [], message: nil }
              end

              def validate_each record, field, value
                return  unless value.present?
                options = default_options.merge(self.options)
                addresses = sanitized_values(value).map { |v| Address.new(v, options[:whitelist], options[:blacklist]) }

                error(record, field) && return unless addresses.all?(&:valid?)

                if options[:whitelist]
                  addresses = addresses.filter { |address| !address.whitelisted? }
                end
                if options[:blacklist]
                  error(record, field) && return if addresses.any?(&:blacklisted?)
                end

              end

              def error(record, field)
                record.errors.add(field, options[:message] || :invalid)
              end

              def sanitized_values(input)
                email_list = input.is_a?(Array) ? input : input.split(',')
                email_list.reject(&:empty?).map(&:strip)
              end

            end

            class Address
              attr_accessor :address

              PROHIBITED_DOMAIN_CHARACTERS_REGEX = /[+!_\/\s'`]/
              DEFAULT_RECIPIENT_DELIMITER = '+'
              DOT_DELIMITER = '.'
              class << self

                def prohibited_domain_characters_regex
                  @prohibited_domain_characters_regex ||= PROHIBITED_DOMAIN_CHARACTERS_REGEX
                end

                def prohibited_domain_characters_regex=(val)
                  @prohibited_domain_characters_regex = val
                end

              end

              def initialize address, whitelist = [], blacklist=[]
                @raw_address = address
                @whitelist = whitelist
                @blacklist = blacklist
                @parse_error = false
                begin
                  @address = Mail::Address.new(address)
                rescue Mail::Field::ParseError
                  @parse_error = true
                end
                @parse_error ||= address_contain_emoticons? @raw_address
              end

              def address_contain_emoticons?(email)
                return false if email.nil?
                email.each_char.any? { |char| char.bytesize > 1 }
              end

              def valid?
                return @valid unless @valid.nil?
                return false if @parse_error
                @valid = valid_domain? && valid_address?
              end

              def valid_address?
                return false if address.address != @raw_address
                  !address.local.include?('..') &&
                  !address.local.end_with?('.') &&
                  !address.local.start_with?('.')
              end

              def valid_domain?
                domain = address.domain
                return false if domain.nil?
                domain !~ self.class.prohibited_domain_characters_regex &&
                  domain.include?('.') &&
                  !domain.include?('..') &&
                  !domain.start_with?('.') &&
                  !domain.start_with?('-') &&
                  !domain.include?('-.')
              end

              def whitelisted?
                domain_is_in? @whitelist || []
              end

              def blacklisted?
                valid? && domain_is_in?(@blacklist || [])
              end

              private

              def domain_is_in? domain_list
                address_domain = address.domain.downcase
                return true if domain_list.include?(address_domain)
                i = address_domain.index('.')
                return false unless i
                domain_list.include?(address_domain[(i + 1)..-1])
              end

            end

          end
        end
      end
    end
  end
end