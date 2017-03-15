# frozen_string_literal: true
require 'spec_helper'
require 'sendgrid/mailer'

describe Sendgrid::Mailer do
  include Mail::Matchers

  it 'has a version number' do
    expect(Sendgrid::Mailer::VERSION).not_to be nil
  end

  describe '#send_mail' do
    subject { Sendgrid::Mailer.new(api_key, from, bcc, env: env, delivery_method: delivery_method, sandbox_mode: sandbox_mode, dev_catch_all: dev_catch_all) }

    let(:env) { :test }
    let(:sandbox_mode) { false }
    let(:dev_catch_all) { false }
    let(:template_id) { ENV['TEMPLATE_ID'] }
    let(:api_key) { ENV['SENDGRID_API_KEY'] }
    let(:from) { 'from@example.com' }
    let(:to) { 'to@example.com' }
    let(:bcc) { 'bcc@example.com' }
    let(:options) do
      {
        to: to,
        template_id: template_id,
        substitutions: {
          foo: 'foo',
          bar: 'bar'
        }
      }
    end

    before do
      Mail::TestMailer.deliveries.clear
    end

    context 'with smtp as delivery method' do
      let(:delivery_method) { :smtp }

      before do
        subject.send_mail(options)
      end

      it { is_expected.to have_sent_email }
      it { should have_sent_email.from(from) }
      it { should have_sent_email.to(to) }
    end

    context 'with api as delivery method' do
      let(:delivery_method) { :api }
      let(:sendgrid_api) { instance_double(SendGrid::API) }
      let(:client) { double('client') }
      let(:mail) { double('mail') }
      let(:send) { double('send') }

      before do
        allow(SendGrid::API).to receive(:new) { sendgrid_api }
      end

      let(:expected_requested_body) do
        {
          'from' => {
            'email' => from
          },
          'personalizations' => [
            {
              'to' => [
                {
                  'email' => to
                }
              ],
              'bcc' => [
                {
                  'email' => bcc
                }
              ],
              'substitutions' => {
                '{{foo}}' => 'foo',
                '{{bar}}' => 'bar'
              }
            }
          ],
          'template_id' => template_id,
          'mail_settings' => {
            'sandbox_mode' => {
              'enable' => sandbox_mode
            }
          }
        }
      end

      it 'sends POST request to SendGrid' do
        expect(sendgrid_api).to receive(:client) { client }
        expect(client).to receive(:mail) { mail }
        expect(mail).to receive(:_).with('send') { send }
        expect(send).to receive(:post).with(request_body: expected_requested_body)
        subject.send_mail(options)
      end
    end

    context 'with unknown delivery method' do
      let(:delivery_method) { :foo }

      it { expect { subject.send_mail(options) }.to raise_error(RuntimeError) }
    end
  end
end
