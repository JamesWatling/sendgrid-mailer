This is a simple helper used as a proof of concept to allow more complex JSON structures with the sendgrid templating system

Allows you to easily find templates and provide variables to the templating system


```ruby
    mail_options = {
      to: user.email,
      template_id: Mailers::SendgridTemplateHelper.get_id_for(:email_confirmation, user.locale),
      substitutions: {
        username: user.email.split('@')[0],
        confirmation_url: confirmation_url(user, confirmation_token: token || user.confirmation_token),
      },
    }.merge(options)
    sendgrid_mail(mail_options)
```

```
  Mailers::SendgridTemplateHelper.get_id_for
  # Returns the sendgrid id for a specific template (currently coming from a yml file)
```

```
  sendgrid_mail
  # creates the json and makes the post request to sendgrid
```


Simple configuration is as follows
```
config/sendgrid_mailer.yml
default: &default
  api_key: <%= ENV['SENDGRID_KEY'] %>
  default_from: 'GuavaPass.com (noreply) <noreply@guavapass.com>'
  default_bcc: 'test@guavapass.com'
  templates:
    email_confirmation:
      en: 343434-0c05-41a3-a5e5-123123
    gift_redemption:
      en: 324234-f2f6-4643-8175-23231
    gifter_confirmation:
      en: 324234234-e3e5-47c9-b299-2323
      fr: 324234234-e3e5-47c9-b299-2323
    pause_confirmation:
      en: 123123123-cd74-4826-a779-123123
```
