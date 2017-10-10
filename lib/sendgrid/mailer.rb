require "sendgrid/mailer/version"
require "sendgrid/template"
require 'sendgrid-ruby'
require 'json'
require 'base64'

module Sendgrid
  class Mailer
    include SendGrid

    def initialize(api_key, from, bcc, sandbox_mode: false, dev_catch_all: false)
      @api_key       = api_key
      @from          = from
      @bcc           = bcc
      @sandbox_mode  = sandbox_mode
      @dev_catch_all = dev_catch_all
    end

    def build_mail_json(template_id:, to: nil, from: nil, reply_to: nil, bcc: nil, substitutions: {}, options: {})
        options = {
          force_send: @sandbox_mode,
        }.merge(options)

        if @dev_catch_all
          to = @dev_catch_all
          bcc = nil
        end

        SendGrid::Mail.new.tap do |m|
          m.from = build_from(from)
          m.template_id = template_id if template_id

          m.personalizations = build_personalization(to, bcc, nil_to_zero_value(substitutions))

          options[:attachments]&.each do |opt|
            m.attachments = build_attachment(opt)
          end

          if reply_to
            m.reply_to = Email.new(email: reply_to)
          end

          if !options[:force_send] && (defined?(Rails) && !Rails.env.production?)
            m.mail_settings = SendGrid::MailSettings.new.tap do |s|
              s.sandbox_mode = SendGrid::SandBoxMode.new(enable: true)
            end
          end
        end.to_json
      end

      def send_mail(options)
        options = build_mail_json(options)
        send_grid.client.mail._('send').post(request_body: options)
      end

      private

      def nil_to_zero_value(substitutions)
        params = substitutions.dup
        params.each { |k,v| params[k] = "" if v.nil? }
        params
      end

      def build_field(field_name, object, values, defaults = nil)
        if values && values.is_a?(Array)
          values.each do |v|
            object.send("#{field_name}=", parse_email(v))
          end
        else
          object.send("#{field_name}=", parse_email(values || defaults))
        end

        object
      end

      def build_from(from)
        parse_email(from || @from)
      end

      def build_personalization(to, bcc, substitutions)
        SendGrid::Personalization.new.tap do |p|
          p = build_field(:to, p, to)

          p = build_field(:bcc, p, bcc, @bcc)

          if substitutions
            substitutions.each do |k, v|
              p.substitutions = SendGrid::Substitution.new(
                                  key: "{{#{k}}}",
                                  value: v.respond_to?(:strip) ? v.strip : v
                                )
            end
          end
        end
      end

      def build_attachment(option)
        attachment = SendGrid::Attachment.new
        attachment.content = Base64.strict_encode64(option[:content])
        attachment.filename = option[:filename]
        attachment
      end

      def parse_email(value)
        output = if value.is_a? Hash
                  raise "No key :email found" unless value[:email]

                  value
                elsif split = value.match(/(.+?)<(.+)>/)
                  {
                    name: split[1].strip,
                    email: split[2].strip,
                  }
                else
                  { email: value.strip }
                end

        SendGrid::Email.new(output)
      end

      def send_grid
        @sendgrid ||= SendGrid::API.new(api_key: @api_key)
      end
  end
end
