# Sendgrid Mailer

This is a simple helper used as a proof of concept to allow more complex JSON structures with the SendGrid Transactional Template.

Allows you to easily find templates and provide variables to the template.

## Install

Add this to your Gemfile and `bundle install`

```
gem 'sendgrid-mailer'
```

## Usage

### Rails

1. Configure the `sendgrid-mailer` like so:

    ```yaml
    # config/sendgrid_mailer.yml

    default: &default
      api_key: <%= ENV['SENDGRID_API_KEY'] %>
      default_from: 'example.com (noreply) <noreply@example.com>'
      default_bcc: 'bcc@example.com'
      templates:
        email_confirmation:
          en: 343434-0c05-41a3-a5e5-123123
        password_reset_confirmation:
          en: 324234234-e3e5-47c9-b299-2323
          fr: 324234234-e3e5-47c9-b299-2323
    ```

    **Configuration**

    1. `api_key` - The SendGrid API key.
    2. `default_from` - The default where the email is sending from.
    3. `default_bcc` - The default where the email will bcc to.
    4. `templates` - The template id for the emails with different locale.
    5. `delivery_method` - How the email will be delivered.
        * `:api` - Delivery the email via SendGrid API. (default)
        * `:smtp` - Deliver the email via SMTP. This is particularly useful for local testing with [mailcatcher](https://github.com/sj26/mailcatcher). The default SMTP settings follow what is in the `Mail` gem, which is `{ address: 'localhost', port: 1025 }`
    6. `env` - The environment. It could be any value, but if it's set to `:production`, it'll never go into the sandbox mode.

2. Initialize the `SendGrid::Mailer`.

    ```ruby
    # config/initializers/sendgrid_mailer.rb

    SendgridMailer = Sendgrid::Mailer.new(
      api_key,
      from,
      bcc,
      sandbox_mode: sandbox_mode,
      dev_catch_all: dev_catch_all,
      smtp_settings: smtp_settings
    )
    SendgridTemplates = Sendgrid::Template.new(templates)
    ```

3. Use it anywhere.

    ```ruby
    # Get the template id for a specific locale from the configuration above
    templated_id = Mailers::SendgridTemplateHelper.get_id_for(:email_confirmation, :en)

    # Build the options for the template
    mail_options = {
      to: user.email,
      template_id: template_id,
      substitutions: {
        username: user.email.split('@')[0],
        confirmation_url: confirmation_url(user, confirmation_token: token || user.confirmation_token),
      },
    }.merge(options)

    # Utilize `SendGrid::API` to send the email
    sendgrid_mail(mail_options)
    ```

## Development

**Setting up the environment variables**

1. Get the [SENDGRID_API_KEY](https://app.sendgrid.com/settings/api_keys). Make sure the key has at least **read-access` to the **Template Engine**.
2. [Create a template](https://sendgrid.com/templates) for testing.

```bash
echo "export SENDGRID_API_KEY=XXXXXX" > .env
echo "export TEST_TEMPLATE_ID=YYYYYY" > .env
source .env
```

**Run the specs**

```bash
bundle exec rspec
```

## Licence

[MIT License](https://opensource.org/licenses/MIT)
