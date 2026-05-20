---
name: Rails Model
description: Create well-structured Rails models with validations, associations, and tests
triggers:
  - create model
  - add model
  - model for
---

# Rails Model Creation

## Model Structure Pattern

````ruby
class ModelName < ApplicationRecord
  # Constants
  STATUSES = %w[draft published archived].freeze

  # Enums
  enum :status, { draft: 0, published: 1, archived: 2 }

  # Validations (alphabetical)
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true, length: { maximum: 255 }
  validates :status, inclusion: { in: STATUSES }

  # Associations (alphabetical)
  belongs_to :user
  has_many :comments, dependent: :destroy
  has_one :profile, dependent: :destroy

  # Scopes (alphabetical)
  scope :active, -> { where(active: true) }
  scope :recent, -> { order(created_at: :desc) }
  scope :published, -> { where(status: :published) }

  # Callbacks (use sparingly)
  before_validation :normalize_email, on: :create
  after_create_commit :notify_admin

  # Class methods
  def self.search(query)
    where("name ILIKE ?", "%#{query}%")
  end

  # Instance methods
  def full_name
    "#{first_name} #{last_name}"
  end

  private

  def normalize_email
    self.email = email.downcase.strip if email.present?
  end

  def notify_admin
    AdminMailer.new_record(self).deliver_later
  end
end

### 5.2 Rails Controller Skill

---
name: Rails Controller
description: Create RESTful Rails controllers with Turbo support
triggers:
  - create controller
  - add controller
  - controller for
---

# Rails Controller Creation

## Controller Pattern

```ruby
class PostsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_post, only: %i[show edit update destroy]
  before_action :authorize_post, only: %i[edit update destroy]

  def index
    @posts = Post.published.recent.page(params[:page])
  end

  def show
  end

  def new
    @post = current_user.posts.build
  end

  def create
    @post = current_user.posts.build(post_params)

    if @post.save
      redirect_to @post, notice: "Post created successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @post.update(post_params)
      redirect_to @post, notice: "Post updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @post.destroy
    redirect_to posts_path, notice: "Post deleted.", status: :see_other
  end

  private

  def set_post
    @post = Post.find(params[:id])
  end

  def authorize_post
    redirect_to posts_path, alert: "Not authorized." unless @post.user == current_user
  end

  def post_params
    params.require(:post).permit(:title, :body, :published)
  end
end


### 5.3 Stimulus Controller Skill

---
name: Stimulus Controller
description: Create Stimulus controllers for JavaScript interactivity
triggers:
  - stimulus
  - js controller
  - javascript controller
  - interactivity
---

# Stimulus Controller Creation

## Basic Pattern

// app/javascript/controllers/example_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  // Define elements to reference
  static targets = ["input", "output"]

  // Define CSS classes to toggle
  static classes = ["active", "hidden"]

  // Define configurable values
  static values = {
    url: String,
    refreshInterval: { type: Number, default: 5000 }
  }

  // Lifecycle: when controller connects to DOM
  connect() {
    console.log("Controller connected")
  }

  // Lifecycle: when controller disconnects
  disconnect() {
    console.log("Controller disconnected")
  }

  // Action methods (called from data-action)
  submit(event) {
    event.preventDefault()
    this.outputTarget.textContent = this.inputTarget.value
  }

  toggle() {
    this.element.classList.toggle(this.activeClass)
  }

  // Value change callbacks
  urlValueChanged() {
    this.load()
  }
}
````

---

## Phase 6: Custom Agents

### 6.1 Rails Reviewer Agent

**File:** `~/.claude/agents/rails-reviewer.md`

```markdown
---
name: rails-reviewer
description: Reviews Rails code for security, performance, and Rails conventions
tools: Read, Grep, Glob
model: sonnet
---

You are a senior Rails developer reviewing code. Focus on:

## Security (Critical)

- SQL injection (use parameterized queries)
- XSS (escape output, use safe methods)
- CSRF protection (verify_authenticity_token)
- Mass assignment (strong parameters)
- Authentication/authorization checks
- Secrets exposure (no hardcoded credentials)

## Performance

- N+1 queries (use includes/preload)
- Missing database indexes
- Inefficient queries
- Memory bloat (large collections)
- Unnecessary callbacks

## Rails Conventions

- RESTful routes and actions
- Thin controllers, fat models (but not too fat)
- Service objects for complex logic
- Concerns for shared behavior
- Proper use of validations
- Test coverage

## Code Quality

- Method length (< 15 lines ideal)
- Class length (< 200 lines)
- Single responsibility
- Clear naming
- DRY without over-abstraction

Provide specific file:line references and concrete fix suggestions.
```

### 6.3 Rails Migration Agent

**File:** `~/.claude/agents/rails-migration.md`

````markdown
---
name: rails-migration
description: Creates safe, reversible Rails database migrations
tools: Read, Write, Bash, Glob
model: sonnet
---

You are a database migration expert for Rails.

## Migration Best Practices

### Always

- Make migrations reversible when possible
- Add indexes for foreign keys
- Add indexes for columns used in WHERE/ORDER
- Use `null: false` with defaults for new columns
- Consider data migration separately from schema

### Column Additions

```ruby
# Safe: add with default, then remove default
add_column :posts, :status, :integer, default: 0, null: false
```
````

---

## Phase 7: MCP Servers

### 7.1 Recommended MCP Servers for Rails

```bash
# GitHub integration (PRs, issues)
claude mcp add github -- npx -y @modelcontextprotocol/server-github

# PostgreSQL (if switching from SQLite)
claude mcp add postgres -- npx -y @modelcontextprotocol/server-postgres

# Sequential thinking for complex problems
claude mcp add thinking -- npx -y @modelcontextprotocol/server-sequential-thinking

# Context7 for live documentation
claude mcp add context7 -- npx -y context7-mcp
```
