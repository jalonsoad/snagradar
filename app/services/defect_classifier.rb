# Rules-based defect classifier — turns free-text defect descriptions
# into trade + priority suggestions. Ships as the MVP-optional AI Trade
# Suggestion + AI Priority Detection from § 7 of the master doc.
#
# Designed for a future swap to an LLM call: same interface
# (`.suggest(text, organization:)`) and same shape returned, just
# different brains.
#
# Usage:
#   DefectClassifier.suggest("Water on the floor under kitchen sink", organization: Current.organization)
#   # => { trade_id: 42, trade_name: "Plumbing", trade_score: 6,
#          priority: "high", priority_score: 4,
#          matched_keywords: ["water", "leak", "kitchen"] }
class DefectClassifier
  TRADE_RULES = {
    "Plumbing"   => %w[leak leaking water tap faucet sink drain toilet wc loo flush pipe shower bath boiler hot\ water cold\ water cistern overflow blockage drip damp soaking radiator pressure],
    "Electrical" => %w[electric electrical socket plug switch wire wiring flicker flickering light lights bulb power tripping fuse breaker board mcb consumer\ unit shock spark exposed extractor fan],
    "Carpentry"  => %w[door doors handle hinge frame skirting skirtings architrave loose wobble wobbly squeaky banister handrail stairs step kitchen\ unit cabinet hinges shelves shelf drawer drawers floorboard],
    "Decorating" => %w[paint painting touch-up touchup wallpaper scuff mark scratch chip stain decoration finish smear smudge wall ceiling cracked\ paint],
    "Tiling"     => %w[tile tiles tiling grout mosaic cracked\ tile loose\ tile bathroom\ floor missing\ tile chipped\ tile],
    "Roofing"    => %w[roof tile\ roof slate gutter guttering downpipe leak\ from\ roof flashing chimney loft attic vent],
    "Glazing"    => %w[window windows glass glazing pane cracked\ window double\ glazed broken\ window sash frame\ window seal misted],
    "General"    => %w[general other miscellaneous misc unknown handyman small\ job]
  }.freeze

  PRIORITY_RULES = {
    "urgent" => %w[urgent emergency dangerous unsafe smoke gas leak\ gas gas\ leak no\ heating no\ hot\ water no\ power flood flooding broken\ glass exposed\ wire shock fire vulnerable\ resident elderly disabled child],
    "high"   => %w[leak leaking water\ damage damp tripping flicker safety hazard sharp risk no\ shower no\ toilet],
    "medium" => %w[door window heating loose wobble wobbly noisy squeak draught stuck],
    "low"    => %w[touch-up touchup mark scuff scratch paint cosmetic minor small finish]
  }.freeze

  def self.suggest(text, organization:)
    new(text, organization: organization).suggest
  end

  def initialize(text, organization:)
    @text = text.to_s.downcase
    @org  = organization
  end

  def suggest
    matched = []

    trade_name, trade_score = top_match(TRADE_RULES) { |kw| matched << kw }
    trade = @org.trades.find_by("LOWER(name) = ?", trade_name.to_s.downcase) if trade_name

    priority_name, priority_score = top_match(PRIORITY_RULES)

    {
      trade_id:        trade&.id,
      trade_name:      trade_name,
      trade_score:     trade_score,
      priority:        priority_name,
      priority_score:  priority_score,
      matched_keywords: matched.uniq.first(8),
      source:          "rules"
    }
  end

  private

  def top_match(rules)
    scores = rules.transform_values do |keywords|
      keywords.sum do |kw|
        if @text.include?(kw)
          yield(kw) if block_given?
          # exact word boundary gets a bigger nudge
          @text.match?(/\b#{Regexp.escape(kw)}\b/) ? 2 : 1
        else
          0
        end
      end
    end

    top = scores.max_by { |_, score| score }
    return [ nil, 0 ] if top.nil? || top.last.zero?
    top
  end
end
