# Controllers

Controllers are thin HTTP adapters.

## Read vs Write

- Reads can load models or query objects and render views.
- Writes call transactions.
- Controllers should not contain orchestration, retries, or cross-record business logic.

## Input Handling

- Use forms for HTML-backed mutation flows when Rails form integration is needed.
- Pass explicit objects into transactions.
- Do not populate hidden request globals for downstream code.

## Response Handling

- Branch on transaction success or failure.
- Keep redirect/render decisions in the controller.
- Keep business decisions in the transaction.

## Example Shape

```ruby
def update
  form = Movies::UpdateForm.new(movie:, params: params[:movie]&.to_unsafe_h)

  form.to_monad
    .bind { |valid_form| Movies::Update.call(movie:, form: valid_form, user: current_user) }
    .fmap { redirect_to movie_path(movie), notice: t(".success") }
    .or   { render Views::Movies::Edit.new(movie:, form:), status: :unprocessable_entity }
end
```
