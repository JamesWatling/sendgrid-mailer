# frozen_string_literal: true
require 'sendgrid/mailer/version'
require 'sendgrid/template'
require 'sendgrid-ruby'
require 'json'
require 'mail'

module Sendgrid
  class Mailer
    include SendGrid

    def initialize(api_key, from, bcc, env: :production, delivery_method: :api, sandbox_mode: false, dev_catch_all: false)
      @api_key       = api_key
      @from          = from
      @bcc           = bcc
      @env = env
      @delivery_method = delivery_method
      @sandbox_mode  = sandbox_mode
      @dev_catch_all = dev_catch_all
    end

    def build_mail_json(template_id:, to: nil, from: nil, bcc: nil, substitutions: {}, options: {})
      options = {
        force_send: @sandbox_mode
      }.merge(options)

      if @dev_catch_all
        to = @dev_catch_all
        bcc = nil
      end

      SendGrid::Mail.new.tap do |m|
        m.from = build_from(from)
        m.template_id = template_id if template_id

        m.personalizations = build_personalization(to, bcc, substitutions)

        if !options[:force_send] && !production?
          m.mail_settings = SendGrid::MailSettings.new.tap do |s|
            s.sandbox_mode = SendGrid::SandBoxMode.new(enable: @sandbox_mode)
          end
        end
      end.to_json
    end

    def send_mail(options)
      case @delivery_method
      when :smtp
        send_mail_via_smtp(options)
      when :api
        options = build_mail_json(options)
        send_grid.client.mail._('send').post(request_body: options)
      else
        raise "Unknown delivery method `#{@delivery_method}`. Available delivery methods are :smtp and :api."
      end
    end

    private

    def production?
      @env == :production
    end

    def send_mail_via_smtp(options)
      template_id = options[:template_id]
      resp = send_grid.client.templates._(template_id).get
      template = JSON.parse(resp.body)['versions'].find { |v| v['active'] == 1 }
      body_html = template['html_content']
      options[:substitutions].each do |k, v|
        body_html.gsub!("{{#{k}}}", v)
      end

      from = build_from(@from).email
      ::Mail.deliver do
        from from
        to options[:to]
        subject template['subject']

        html_part do
          content_type 'text/html; charset=UTF-8'
          body body_html
        end
      end
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

        substitutions&.each do |k, v|
          p.substitutions = SendGrid::Substitution.new(
            key: "{{#{k}}}",
            value: v
          )
        end
      end
    end

    def parse_email(value)
      output = if value.is_a? Hash
                 raise 'No key :email found' unless value[:email]
                 value
               elsif split = value.match(/(.+?)<(.+)>/)
                 {
                   name: split[1].strip,
                   email: split[2].strip
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
