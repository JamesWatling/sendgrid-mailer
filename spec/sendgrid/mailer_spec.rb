require 'spec_helper'

RSpec.describe Sendgrid::Mailer, type: :initializer do
  let(:mailer) do
    api_key = 'marcosface'
    from = 'GuavaPass.com (noreply) <noreply@guavapass.com>'
    bcc = 'dev_catchall@guavapass.com'
    Sendgrid::Mailer.new(api_key, from, bcc)
  end

  describe '#build_mail_json' do
    context '1 recipient' do
      let(:mail_data) do
        {
          to: 'justin@guavapass.com',
          template_id: '1459d62f-0c05-41a3-a5e5-875124647940',
          substitutions: {
            username: 'meowmixultra',
            confirmation_url: 'https://guavapass.com',
          },
        }
      end

      subject { mailer.build_mail_json(mail_data) }

      it { is_expected.to eq({"from"=>{"email"=>"noreply@guavapass.com", "name"=>"GuavaPass.com (noreply)"}, "personalizations"=>[{"to"=>[{"email"=>"justin@guavapass.com"}], "bcc"=>[{"email"=>"dev_catchall@guavapass.com"}], "substitutions"=>{"{{username}}"=>"meowmixultra", "{{confirmation_url}}"=>"https://guavapass.com"}}], "template_id"=>"1459d62f-0c05-41a3-a5e5-875124647940"}) }
    end

    context '1 recipient with name' do
      let(:mail_data) do
        {
          to: 'Justin <justin@guavapass.com>',
          template_id: '1459d62f-0c05-41a3-a5e5-875124647940',
          substitutions: {
            username: 'meowmixultra',
            confirmation_url: 'https://guavapass.com',
          },
        }
      end

      subject { mailer.build_mail_json(mail_data) }

      it { is_expected.to eq({"from"=>{"email"=>"noreply@guavapass.com", "name"=>"GuavaPass.com (noreply)"}, "personalizations"=>[{"to"=>[{"email"=>"justin@guavapass.com", "name"=>"Justin"}], "bcc"=>[{"email"=>"dev_catchall@guavapass.com"}], "substitutions"=>{"{{username}}"=>"meowmixultra", "{{confirmation_url}}"=>"https://guavapass.com"}}], "template_id"=>"1459d62f-0c05-41a3-a5e5-875124647940"}) }
    end

    context 'multi recipient with multi-format' do
      let(:mail_data) do
        {
          to: ['Justin <justin@guavapass.com>', 'james@guavapass.com', { email: 'whatwhat@inthebutt.com', name: 'Kenny Southpark'}],
          template_id: '1459d62f-0c05-41a3-a5e5-875124647940',
          substitutions: {
            username: 'meowmixultra',
            confirmation_url: 'https://guavapass.com',
          },
        }
      end

      subject { mailer.build_mail_json(mail_data) }

      it { is_expected.to eq("from"=>{"email"=>"noreply@guavapass.com", "name"=>"GuavaPass.com (noreply)"}, "personalizations"=>[{"to"=>[{"email"=>"justin@guavapass.com", "name"=>"Justin"}, {"email"=>"james@guavapass.com"}, {"email"=>"whatwhat@inthebutt.com", "name"=>"Kenny Southpark"}], "bcc"=>[{"email"=>"dev_catchall@guavapass.com"}], "substitutions"=>{"{{username}}"=>"meowmixultra", "{{confirmation_url}}"=>"https://guavapass.com"}}], "template_id"=>"1459d62f-0c05-41a3-a5e5-875124647940") }
    end

    context 'no :email, throws error' do
      let(:mail_data) do
        {
          to: ['Justin <justin@guavapass.com>', 'james@guavapass.com', { emailz: 'whatwhat@inthebutt.com', name: 'Kenny Southpark'}],
          template_id: '1459d62f-0c05-41a3-a5e5-875124647940',
          substitutions: {
            username: 'meowmixultra',
            confirmation_url: 'https://guavapass.com',
          },
        }
      end

      subject { mailer.build_mail_json(mail_data) }

      it { expect{ subject }.to raise_error RuntimeError }
    end

    context 'when substitutions values are nil' do
      let(:mail_data) do
        {
          to: ['Justin <justin@guavapass.com>', 'james@guavapass.com', { email: 'whatwhat@inthebutt.com', name: 'Kenny Southpark'}],
          template_id: '1459d62f-0c05-41a3-a5e5-875124647940',
          substitutions: {
            username: nil,
            confirmation_url: nil,
          },
        }
      end

      subject { mailer.build_mail_json(mail_data) }
      it 'replaces nil to empty string' do
        expect(subject).to eq("from"=>{"email"=>"noreply@guavapass.com", "name"=>"GuavaPass.com (noreply)"}, "personalizations"=>[{"to"=>[{"email"=>"justin@guavapass.com", "name"=>"Justin"}, {"email"=>"james@guavapass.com"}, {"email"=>"whatwhat@inthebutt.com", "name"=>"Kenny Southpark"}], "bcc"=>[{"email"=>"dev_catchall@guavapass.com"}], "substitutions"=>{"{{username}}"=>"", "{{confirmation_url}}"=>""}}], "template_id"=>"1459d62f-0c05-41a3-a5e5-875124647940")
      end
    end

    context 'when substitutions value has trailing/leading spaces' do
      let(:mail_data) do
        {
          to: ['Justin <justin@guavapass.com>', 'james@guavapass.com', { email: 'whatwhat@inthebutt.com', name: 'Kenny Southpark'}],
          template_id: '1459d62f-0c05-41a3-a5e5-875124647940',
          substitutions: {
            username: 'meowmixultra   ',
            confirmation_url: '   https://guavapass.com',
          },
        }
      end

      subject { mailer.build_mail_json(mail_data) }
      it 'strips the leading/trailing spaces' do
        expect(subject).to eq("from"=>{"email"=>"noreply@guavapass.com", "name"=>"GuavaPass.com (noreply)"}, "personalizations"=>[{"to"=>[{"email"=>"justin@guavapass.com", "name"=>"Justin"}, {"email"=>"james@guavapass.com"}, {"email"=>"whatwhat@inthebutt.com", "name"=>"Kenny Southpark"}], "bcc"=>[{"email"=>"dev_catchall@guavapass.com"}], "substitutions"=>{"{{username}}"=>"meowmixultra", "{{confirmation_url}}"=>"https://guavapass.com"}}], "template_id"=>"1459d62f-0c05-41a3-a5e5-875124647940")
      end

    end
  end
end
