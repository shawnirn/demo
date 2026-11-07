# frozen_string_literal: true

# Reads the planner's `claude -p --output-format json` output and prints a
# single-line JSON array of subtasks for the GitHub Actions matrix.
# Falls back to one generic subtask when the plan cannot be parsed.
require "json"

ROLES = %w[researcher architect implementer tester reviewer].freeze
MAX_SUBTASKS = 5

def fallback
  [{ "id" => "general", "role" => "researcher", "title" => "完整處理任務",
     "instructions" => "直接完成使用者的任務，並附上依據。" }]
end

def parse_plan(text)
  candidate = text[/```(?:json)?\s*(\{.*\})\s*```/m, 1] || text[/\{.*\}/m]
  return nil unless candidate

  JSON.parse(candidate)
rescue JSON::ParserError
  nil
end

def normalize(subtasks)
  seen = {}
  subtasks.first(MAX_SUBTASKS).filter_map.with_index do |task, i|
    next unless task.is_a?(Hash)

    id = task["id"].to_s.downcase.gsub(/[^a-z0-9_-]/, "")[0, 30]
    id = "task#{i + 1}" if id.empty? || seen[id]
    seen[id] = true
    {
      "id" => id,
      "role" => ROLES.include?(task["role"]) ? task["role"] : "researcher",
      "title" => task["title"].to_s.strip[0, 100],
      "instructions" => task["instructions"].to_s.strip[0, 4000]
    }
  end
end

raw = File.read(ARGV.fetch(0))
result = begin
  JSON.parse(raw)["result"].to_s
rescue JSON::ParserError
  raw
end

plan = parse_plan(result)
subtasks = plan.is_a?(Hash) && plan["subtasks"].is_a?(Array) ? normalize(plan["subtasks"]) : []
subtasks = fallback if subtasks.empty?
puts JSON.generate(subtasks)
