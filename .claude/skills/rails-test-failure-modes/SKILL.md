---
name: Rails Test Failure Modes
description: Write Rails tests that catch real bugs by targeting failure modes — tamper attempts, edge values, race conditions, nil paths, malformed input — rather than only happy paths. Use Minitest or RSpec; use when the user asks for more rigorous tests, security-grade tests, or hardening coverage.
triggers:
  - write better tests
  - add failure-mode tests
  - test edge cases
  - improve test coverage
  - test for security
  - tests that catch bugs
---

# Rails Test Failure-Mode Hardening

Use this skill when the user asks for *better* tests, not *more* tests. The goal is tests that catch bugs the codebase will actually ship, not tests that mirror the implementation.

## Pre-flight: read the code first

Before writing a single test, scan the target class with these questions:

1. **What inputs can be nil that the code assumes won't be?**
2. **What database constraints exist (uniqueness, NOT NULL, foreign keys)?**
3. **What external services does the method call, and how do they fail?**
4. **What's the longest-lived state in this object, and what can stale it?**
5. **What happens if the user calls this method twice?**
6. **What happens if two requests run this method concurrently?**

If you can't answer all six, you don't have enough context yet — ask the user or read the model/controller more carefully.

## The seven failure-mode categories to cover

For every non-trivial controller / model / service, the test file must include at least one assertion from each applicable category below.

### 1. Tamper / injection paths

Always try to break security boundaries through the same interface a real attacker uses.

```ruby
test "wizard refuses tokens that look like SQL fragments" do
  sqli = URI.encode_www_form_component(%q(' OR '1'='1))
  get "/s/#{'a' * 48}#{sqli}"
  assert_redirected_to survey_invalid_url
end

test "submitting answers for off-step questions is silently ignored" do
  patch survey_step_url(token: inv.token, step: 1), params: {
    answers: { off_step_question.id.to_s => "trying to inject" }
  }
  assert_nil inv.reload.survey_response.answer_for(off_step_question)
end
```

### 2. Idempotency / replay

What happens if the same operation runs twice?

```ruby
test "completing the wizard a second time keeps original completed_at" do
  inv = survey_invitations(:completed)
  original = inv.completed_at
  travel 1.day do
    patch survey_step_url(token: inv.token, step: 5), params: { answers: {} }
  end
  assert_equal original.to_i, inv.reload.completed_at.to_i
end

test "mark_opened! is idempotent" do
  inv = survey_invitations(:sent)
  inv.mark_opened!
  first = inv.opened_at
  inv.mark_opened!
  assert_equal first.to_i, inv.opened_at.to_i
end
```

### 3. Boundary / clamping

Off-by-one is the most common bug. Every numeric parameter needs both ends + one past.

```ruby
test "wizard clamps an out-of-range step parameter back into 1..5" do
  get survey_step_url(token: @inv.token, step: 999)
  assert_match "Paso 5 de", response.body
end

test "wizard clamps negative step values to 1" do
  get survey_step_url(token: @inv.token, step: -3)
  assert_match "Paso 1 de", response.body
end
```

### 4. Nil / missing / empty input

The model `assumes` something is there; assert the behavior when it isn't.

```ruby
test "csat returns 0.0 when no completed responses have a csat answer" do
  Answer.where(question: questions(:csat)).destroy_all
  assert_equal 0.0, KpiReport.new.csat
end

test "duration_seconds nil when missing timestamps" do
  resp = SurveyResponse.new
  assert_nil resp.duration_seconds
end

test "ai_demand_percentage handles zero responses" do
  Answer.where(question: questions(:ai_demand)).destroy_all
  assert_equal 0, KpiReport.new.ai_demand_percentage
end
```

### 5. Type / shape coercion

The DB column allows it, the code probably doesn't.

```ruby
test "nps survives non-numeric junk in the answer payload" do
  answers(:completed_nps).update!(value: { "data" => "not-a-number" })
  assert_nothing_raised { KpiReport.new.nps }
end
```

### 6. External-service failure

The article calls this out as the #1 hollow-test area. Always raise the failures the dependency can actually throw.

```ruby
test "smtp failure shows the actual exception in the alert" do
  failing = Module.new do
    def invite(_inv)
      raise Net::SMTPAuthenticationError, "535 Authentication failed"
    end
  end
  SurveyMailer.singleton_class.prepend(failing)

  post resend_admin_invitation_url(inv)
  assert_match "Net::SMTPAuthenticationError", flash[:alert]
end
```

Find the real exceptions a gem raises (`grep -rn 'raise ' gem-source/lib/`). Don't invent generic `StandardError` — match the real class so the test traces back to real production behavior.

### 7. Authorization / access

For every authenticated endpoint, write the negative case.

```ruby
test "admin namespace requires authentication" do
  %w[/admin /admin/dashboard /admin/invitations /admin/questions /admin/feedback /admin/smtp].each do |path|
    get path
    assert_redirected_to new_session_url, "expected #{path} to redirect to login"
  end
end
```

## The prompt that changes AI test quality

When asking an AI to write Rails tests, *don't* use "write tests for this class". The output will be 30 happy paths and zero bug-catchers. Use this framing instead:

> You are a senior Rails engineer reviewing this class for production safety.
> For each public method, identify the riskiest input combinations.
> Write Minitest tests that verify FAILURE modes, not just happy paths.
> Assume the database can return nil, external calls can time out, and
> users will pass malformed input. Schema and external-service notes follow.

Then paste:
- The schema for the table the model maps to
- The exact exception classes external services raise (`Net::SMTPAuthenticationError`, `Stripe::InvalidRequestError`, etc.)
- Any soft-delete / default-scope behavior that's not visible from the class file
- The actual bug from the most recent post-mortem if there is one

That single prompt change cuts hollow tests by ~60% in our experience.

## What to do with red tests from generated suites

When an AI-generated test fails on the codebase, the instinct is to assume the test is wrong. **Often it isn't.** Re-read the assertion:

- If the test expected the method to handle nil and the method raised → the **code** is missing defensive handling. Fix the code.
- If the test expected a business rule that doesn't apply (e.g. "raises on tax = 0" when zero is valid for nonprofits) → the **test** has wrong domain assumptions. Delete it.
- If you can't tell which side is wrong → that's the most valuable test of all. It surfaced an ambiguity. Talk to the product owner before deleting.

## Signals that your suite is hollow

Even with a high run count, suspect a hollow suite when:

- **The bug-catch rate is below 20% of new tests**. Track this in PR descriptions for 30 days. If most generated tests only confirm known behavior, the prompting needs more failure-mode framing.
- **Tests assert on implementation, not behavior** — e.g. `assert_called(:foo)` instead of asserting the outcome that calls `foo`. These tests block legitimate refactors without catching bugs.
- **Mocks return the happy-path value of the dependency**. Real services time out, return 5xx, return 200 with an error body. Mock those, not the 200 OK.

## What to track

Coverage % is not the signal. Track these instead in `tmp/test-quality.md` (or a similar local file the project doesn't ship):

| Month | New tests added | Tests that caught a bug | Ratio |
|---|---|---|---|
| 2026-05 | 30 | 3 | 10% |
| 2026-06 | 12 | 4 | 33% |

Bug here means: a test caused a code change to a non-test file. Pure assertions of known behavior don't count. The ratio is the truth metric.

## Pairing with rails-security skill

When the user asks for security-flavored tests, this skill and the **rails-security** skill compose:
- `rails-security` says *what to defend* (sessions, tokens, brute-force, audit logs)
- `rails-test-failure-modes` says *how to test the defense*

Always write the test that proves the control works, not just the control itself. Unverified security code is worse than no security code because it creates false confidence.
