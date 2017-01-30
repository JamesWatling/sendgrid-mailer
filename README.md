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
