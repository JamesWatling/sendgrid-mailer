module Sendgrid
  class Template

    attr_reader :templates

    def initialize(templates)
      @templates = templates
    end

    def get_id(name, locale)
      [locale, :en].each do |lang|
        output = @templates.try(:[], name).try(:[], lang)

        return output if output
      end

      raise "No SendGrid template with #{name}, #{locale} nor :en as fallback"
    end
  end
end
