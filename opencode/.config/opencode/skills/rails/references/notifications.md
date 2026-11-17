# Notifications

A notifier tells users about an event through every channel they enabled: email, SMS, push, or in-app.

## Rules

- Transactions trigger notifiers. Models and callbacks never do.
- One notifier per event, in the slice, named `<Domain>::<Event>Notifier`.
- The notifier picks recipients' channels from their preferences. Callers never check preferences.
- Mailers and other channel senders are called only from notifiers.
- Pass the recipient as a parameter (`.with(user:)`) and the event data as arguments.
- Deliver later, after the transaction commits.

```ruby
class Posts::PublishedNotifier
  include App::Deps[:sms]

  def call(post:)
    post.user.subscribers.each do |user|
      prefs = user.notification_preferences
      PostMailer.with(user:).published(post).deliver_later if prefs.email?
      sms.deliver_later(to: prefs.phone_number, body: "New post: #{post.title}") if prefs.sms?
    end
  end
end
```

The transaction now shows its steps:

```ruby
def call(post:)
  publication = post.build_publication(published_at: Time.current)
  return Failure(publication.errors) unless publication.save

  published_notifier.call(post:)
  Success(post)
end
```

## Preferences

Do not add a boolean column to `users` for each channel. Keep preferences in their own model: a separate table, or a `DataModel` in a JSON column. Expose predicates such as `email?` and `sms?` that also check the global opt-out.

## Testing

- Test channel selection in the notifier spec with a fake channel sender.
- In the transaction spec, check only that the notifier was called.
