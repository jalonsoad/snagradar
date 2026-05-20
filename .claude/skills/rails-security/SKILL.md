---
name: Rails Security
description: Audit and harden a Ruby on Rails 8 application against the Rails 8 Security Best Practices guide (sessions, auth, tokens, rate limiting, logging, secrets, infra, monitoring).
triggers:
  - security audit
  - harden the app
  - rails security
  - check for sql injection
  - protect against brute force
  - session security
  - rate limiting
  - rack-attack
---

# Rails Security Hardening

Use when the user asks for a security audit, asks to harden the app, or asks to add specific defensive controls. Walk through the 17 sections below, decide which apply to the codebase, and implement the gaps as concrete code with tests — never just documentation.

## Pre-flight audit checklist

Before recommending any changes, scan the codebase first. Spending 2 minutes on these greps prevents half an hour of bad assumptions:

```bash
# SQL-injection vectors
grep -rnE '\.where\("[^"]*#\{|find_by_sql|execute\(.+#\{|connection\.exec' app/

# Params-as-SQL
grep -rnE 'where.*params\[|order.*params\[|select.*params\[' app/

# Mass-assignment safety
grep -rnE 'params\.require|params\.permit|params\.expect' app/controllers/

# Code-injection vectors
grep -rnE '\bsend\(params|\bpublic_send\(params|constantize|eval\(' app/

# Auth & session config
ls config/initializers/session_store.rb 2>/dev/null
ls config/initializers/rack_attack.rb 2>/dev/null
grep -rn "force_ssl\|assume_ssl" config/environments/production.rb
```

State the findings before writing code. If grep returns empty for SQLi, say so — don't add defenses against threats that aren't present.

---

## 1. Token Security

**Applies when**: app has API tokens, invitation tokens, webhook signing keys, or any random-token gating.

Recommended schema:

```ruby
t.string   :token
t.integer  :purpose          # enum
t.datetime :expires_at
t.datetime :revoked_at
t.datetime :last_used_at
t.string   :last_used_ip
```

Token generation: `SecureRandom.urlsafe_base64(36)` (48 chars). Always check uniqueness and store an index.

```ruby
def assign_token
  self.token ||= loop do
    candidate = SecureRandom.urlsafe_base64(36).first(48)
    break candidate unless self.class.exists?(token: candidate)
  end
end
```

Never log raw tokens (add `:token` to `filter_parameters`). For one-time tokens, store a digest, not the cleartext.

---

## 2. Webhook Security

**Never** compare HMAC signatures with `==` — it's vulnerable to timing attacks. Use:

```ruby
def valid_signature?
  expected = OpenSSL::HMAC.hexdigest("SHA256", secret, request.raw_post)
  actual   = request.headers["X-Signature"].to_s
  ActiveSupport::SecurityUtils.secure_compare(expected, actual)
end
```

Also: replay protection (timestamp + nonce), payload size limits, scope per provider/integration.

---

## 3. Session Security

Drop this in `config/initializers/session_store.rb`:

```ruby
Rails.application.config.session_store :cookie_store,
  key:          "_#{Rails.application.class.module_parent_name.underscore}_session",
  secure:       Rails.env.production?,
  httponly:     true,
  same_site:    :lax,
  expire_after: 12.hours
```

In the sessions controller, call `reset_session` immediately before assigning `session[:user_id]` to mitigate session fixation:

```ruby
def sign_in(user)
  reset_session
  session[:user_id] = user.id
end
```

---

## 4. Redis Security

Only relevant if Redis is in use (Sidekiq, ActionCable, cache). If app uses the Solid trifecta on PG, skip this section.

When Redis is present:

- `bind 127.0.0.1` only
- `protected-mode yes`
- `requirepass <strong-password>`
- Never expose port 6379 to the public internet
- Rotate credentials when developers leave

---

## 5. Multi-Tenant Security

**Never** do `Model.find(params[:id])` on tenant-owned resources. Always scope:

```ruby
Current.account.orders.find(params[:id])
```

If the app uses `default_scope`, audit every `Model.unscoped` call — those bypass tenant isolation. Add integration tests that try to access another tenant's record by guessing IDs and assert 404.

---

## 6. Authentication

For a single-admin app, the minimum:

- `has_secure_password` (bcrypt cost ≥ 10 in production, 4 in tests)
- Email normalized to lowercase + stripped
- `reset_session` on sign-in (anti-fixation)
- Rate-limit `/login` via Rack::Attack (see §8)

For multi-user / SaaS apps add:

- Email verification on signup
- Password reset with single-use, time-limited tokens
- 2FA (TOTP via `rotp` gem) for admin role
- Failed-login lockout (Allow2Ban below)

---

## 7. Authorization

Authentication ≠ authorization. Use Pundit or a similar policy layer for anything beyond a single role. Test the negative cases — assert that a non-admin user gets 403/404 on every admin route.

Minimum check in a controller:

```ruby
before_action :require_admin

def require_admin
  return if current_user&.admin?
  head :forbidden
end
```

---

## 8. Admin & rate-limit hardening (Rack::Attack)

Add `gem "rack-attack"` and an initializer:

```ruby
return if Rails.env.test? # tests use empty UA + rapid auth

Rack::Attack.cache.store = Rails.cache

# Login brute-force
Rack::Attack.throttle("logins/ip", limit: 5, period: 20.seconds) do |req|
  req.ip if req.post? && req.path == "/login"
end
Rack::Attack.throttle("logins/email", limit: 5, period: 20.seconds) do |req|
  req.params["email"]&.downcase if req.post? && req.path == "/login"
end

# fail2ban: 10 failures in 10min → 30-min ban
Rack::Attack.blocklist("fail2ban/login") do |req|
  Rack::Attack::Allow2Ban.filter(req.ip, maxretry: 10, findtime: 10.minutes, bantime: 30.minutes) do
    req.post? && req.path == "/login"
  end
end

# Generic per-IP ceiling
Rack::Attack.throttle("req/ip", limit: 300, period: 5.minutes) do |req|
  req.ip unless req.path == "/up"
end

# Plain-text Spanish/English friendly 429
Rack::Attack.throttled_responder = lambda do |request|
  retry_after = request.env.dig("rack.attack.match_data", :period) || 60
  [ 429, { "Content-Type" => "text/plain", "Retry-After" => retry_after.to_s },
    [ "Too many requests. Try again in #{retry_after}s.\n" ] ]
end
```

**Always exempt the load-balancer health-check path** (`/up`) — getting your origin throttled by your own rate limiter is a common outage.

Other admin protections worth adding for sensitive apps:

- IP allowlist on `/admin/*` (verify against `request.remote_ip`, not headers, behind a known proxy)
- Recent re-authentication for destructive actions (record `session[:reauthed_at]`)
- Audit log on every admin action (see §14)

---

## 9. Secret Management

- Use `bin/rails credentials:edit` per-env
- ENV vars for things the platform owns (DATABASE*URL, SMTP*\*)
- Never commit `*.key`, `.kamal/secrets`, `*.local.{json,md}`
- `.gitignore` patterns to enforce: `/config/*.key`, `/config/credentials/*.key`
- Rotate any secret that's ever been pasted into Slack / logs / a screenshot

---

## 10. Logging Security

In `config/initializers/filter_parameter_logging.rb`:

```ruby
Rails.application.config.filter_parameters += [
  :passw, :password, :password_confirmation, :secret, :api_key, :authorization,
  :access_token, :refresh_token, :_key, :crypt, :salt, :signature,
  :email, :ssn, :otp, :token, :certificate, :cvv, :cvc
]
```

ParameterFilter does substring matching by default, so `:passw` catches `password` and `password_confirmation`. To verify behavior in a test:

```ruby
filter = ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters)
assert_equal "[FILTERED]", filter.filter("password" => "secret")["password"]
```

---

## 11. CSRF Protection

Rails enables `protect_from_forgery` by default in `ApplicationController`. Don't disable it. For JSON-API endpoints, use `protect_from_forgery with: :null_session` _and_ require an auth token — never disable forgery protection without a substitute.

---

## 12. Infrastructure / Transport

Production environment must include:

```ruby
config.assume_ssl = true                     # trust X-Forwarded-Proto from proxy
config.force_ssl  = true                     # redirect http → https + HSTS
config.ssl_options = { redirect: { exclude: ->(r) { r.path == "/up" } } }
config.hosts << ENV.fetch("APP_HOST")        # block Host-header attacks
config.host_authorization = { exclude: ->(r) { r.path == "/up" } }
```

Common pitfall on Hatchbox/Kamal: SSL terminates at the proxy, Rails sees `http://`, `force_ssl` redirects to `https://`, browser loops. `assume_ssl = true` is the fix.

---

## 13. CI/CD Security

Required local commands (all already in `bin/ci` for any healthy Rails project):

- `bin/brakeman --no-pager` — static Rails analysis
- `bin/bundler-audit check --update` — CVE scan of Gemfile.lock
- `bundle exec rails test:all` — full unit + integration + system

For dynamic / runtime testing add `bin/pentest` driving [pentest-ai](https://github.com/0xSteph/pentest-ai). Never put pentest-ai in CI — runtime is too long; it's an on-demand audit, not a per-commit gate. **Hard-fail** the pentest script if `RAILS_ENV=production` or `APP_HOST` resolves to the real production domain.

---

## 14. Monitoring & Audit Logging

At minimum, structured `Rails.logger.tagged("auth")` entries on:

- Successful login
- Failed login (with attempted email, IP, UA)
- Logout
- Privilege change / role grant
- Sensitive admin actions (token issuance/revocation, user deletion)

Example:

```ruby
def log_auth_event(event, user: nil, attempted_email: nil)
  Rails.logger.tagged("auth") do
    Rails.logger.info(
      event:      event,
      user_id:    user&.id,
      email:      user&.email || attempted_email&.to_s&.downcase,
      ip:         request.remote_ip,
      user_agent: request.user_agent,
      request_id: request.request_id
    )
  end
end
```

Pipe these to a log aggregator (Papertrail, Loki, CloudWatch) and alert on:

- > 10 login failures from one IP in 5 min
- Any login outside business hours from a new geolocation
- Mass token revocations
- 5xx spike

---

## 15. Security Testing

Two levels, both required:

1. **Static** — `bin/ci` includes Brakeman + bundler-audit + RuboCop on every commit
2. **Dynamic** — `bin/pentest` (pentest-ai) on demand against a sandboxed `localhost`:
   - SQLi via wrapped sqlmap
   - XSS, CSRF, IDOR, header misconfig
   - Auth bypass / brute-force
   - Dependency CVE scan
   - 60 OWASP probes + Nuclei templates

Schedule a manual pentest at least quarterly, more frequently if shipping fast.

---

## 16. AI / LLM Security

If the app uses an LLM at runtime (chatbot, AI form filler, agent loop):

- Treat all LLM output as untrusted user input (prompt injection mitigation)
- Scope tool access: never let the LLM call destructive controller actions directly
- Require human approval for non-idempotent actions
- Log every LLM tool invocation (function name, args, result)
- Rate-limit LLM endpoints separately from regular traffic
- Never include secrets/PII in the system prompt unless the provider has DPA + zero-retention

---

## 17. Production hardening checklist (copy into PR description)

- [ ] `force_ssl = true` and `assume_ssl = true` in production
- [ ] `config.hosts` populated; `host_authorization` excludes `/up`
- [ ] HSTS / referrer-policy / X-Frame-Options headers verified
- [ ] Session cookie: httponly, secure, same_site, expire_after
- [ ] `reset_session` on sign-in
- [ ] Rack::Attack throttles installed (/login, /s/, generic)
- [ ] Login success + failure → structured `auth` log line
- [ ] `filter_parameters` covers password/token/secret/api_key/signature/authorization
- [ ] Brakeman 0 warnings (`bin/brakeman`)
- [ ] bundler-audit 0 vulnerabilities (`bin/bundler-audit check --update`)
- [ ] `bin/pentest --quick` passes against a clean localhost
- [ ] Master key + `.kamal/secrets` + `*.local.json` gitignored
- [ ] Admin namespace requires authentication AND role check
- [ ] No `Model.find(params[:id])` on tenant-scoped data (if multi-tenant)

---

## When the user pushes back on adding controls

Some teams reflexively reject security work as "yak-shaving". The way to land it is to scope each control to a concrete risk:

- **Rate-limiting**: "blocks the credential-stuffing bots that hit every public login at 5 req/s"
- **Session hardening**: "stops cookie theft via XSS from escalating to full account takeover"
- **Audit logging**: "lets you tell SOC2/ISO27001 what time someone logged in. Free regulatory checkbox."
- **filter_parameters**: "the password your user typed today is in your log file forever otherwise"

Each control should ship with a test that proves it works. If you can't test it, you're not sure it works.
