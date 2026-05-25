# frozen_string_literal: true

require 'json'
require 'yaml'
require 'pathname'

# Locates registry.json from agent-mcp-runtime
registry_path = File.expand_path('../../agent-mcp-runtime/registry.json', __dir__)
unless File.exist?(registry_path)
  puts "FAIL: registry.json not found at #{registry_path}"
  exit 1
end

registry = JSON.parse(File.read(registry_path))
packs = registry['packs']

repos = {}
packs.each do |pack_name, pack_config|
  repo_name = pack_config['source'].split('/').last
  repo_path = File.expand_path("../../#{repo_name}", __dir__)
  unless Dir.exist?(repo_path)
    puts "FAIL: Sibling repository #{repo_name} does not exist at #{repo_path}"
    exit 1
  end
  repos[pack_name] = {
    name: pack_config['source'],
    path: repo_path,
    tile_path: File.join(repo_path, pack_config['tile'] || 'tile.json')
  }
end

# Load tile.json for each repository
repos.each do |pack_name, repo_info|
  unless File.exist?(repo_info[:tile_path])
    puts "FAIL: tile.json not found for #{pack_name} at #{repo_info[:tile_path]}"
    exit 1
  end
  repo_info[:tile] = JSON.parse(File.read(repo_info[:tile_path]))
end

all_passed = true

# 1. Every skill in tile.json has a matching directory with SKILL.md
puts "--- Check 1: Skill Directories and SKILL.md ---"
repos.each do |pack_name, repo_info|
  tile = repo_info[:tile]
  skills = tile['skills'] || {}
  skills.each do |skill_name, skill_info|
    skill_path = File.join(repo_info[:path], skill_info['path'])
    skill_md = skill_path.end_with?('SKILL.md') ? skill_path : File.join(skill_path, 'SKILL.md')
    if File.exist?(skill_md)
      # OK
    else
      puts "FAIL: Skill '#{skill_name}' in pack '#{pack_name}' has missing SKILL.md at #{skill_md}"
      all_passed = false
    end
  end
end

# 2. Every deprecated_skills entry points to a valid skill in the target repo
puts "\n--- Check 2: Deprecated Skills Redirects ---"
repos.each do |pack_name, repo_info|
  tile = repo_info[:tile]
  deprecated = tile['deprecated_skills'] || {}
  deprecated.each do |skill_name, info|
    moved_to = info['moved_to']
    unless moved_to
      puts "FAIL: Deprecated skill '#{skill_name}' in '#{pack_name}' is missing 'moved_to' key"
      all_passed = false
      next
    end

    target_repo_info = repos.values.find { |r| r[:name] == moved_to || r[:name].split('/').last == moved_to.split('/').last }
    if target_repo_info.nil?
      puts "FAIL: Deprecated skill '#{skill_name}' in '#{pack_name}' moved to unknown repo '#{moved_to}'"
      all_passed = false
      next
    end

    target_skills = target_repo_info[:tile]['skills'] || {}
    target_skill_name = info['new_name'] || info['moved_to_skill'] || skill_name
    if target_skills.key?(target_skill_name)
      # OK
    else
      puts "FAIL: Deprecated skill '#{skill_name}' in '#{pack_name}' moved to '#{moved_to}' (target skill: '#{target_skill_name}'), but skill is missing in target repo's tile.json"
      all_passed = false
    end
  end
end

# 3. depends_on repos exist and have tile.json
puts "\n--- Check 3: Sibling depends_on Repositories ---"
packs.each do |pack_name, pack_config|
  depends_on = pack_config['depends_on'] || []
  depends_on.each do |dep_pack|
    unless packs.key?(dep_pack)
      puts "FAIL: Pack '#{pack_name}' in registry depends on unknown pack '#{dep_pack}'"
      all_passed = false
    end
  end
end

repos.each do |pack_name, repo_info|
  tile = repo_info[:tile]
  depends_on = tile['depends_on'] || []
  depends_on.each do |dep_repo|
    target_repo_info = repos.values.find { |r| r[:name] == dep_repo || r[:name].split('/').last == dep_repo.split('/').last }
    if target_repo_info.nil?
      puts "FAIL: Repo '#{repo_info[:name]}' depends on unknown repo '#{dep_repo}'"
      all_passed = false
    else
      unless File.exist?(target_repo_info[:tile_path])
        puts "FAIL: Sibling dependency repo '#{dep_repo}' tile.json is missing"
        all_passed = false
      end
    end
  end
end

# 4. No skill name appears in >1 repo's tile.json (within a pack stack)
puts "\n--- Check 4: Skill Key Uniqueness in Pack Stack ---"
def resolve_stack(pack_name, packs, visited = [])
  return [] if visited.include?(pack_name)
  visited = visited + [pack_name]

  pack_config = packs[pack_name]
  return [] unless pack_config

  stack = [pack_name]
  depends_on = pack_config['depends_on'] || []
  depends_on.each do |dep_pack|
    stack += resolve_stack(dep_pack, packs, visited)
  end
  stack.uniq
end

packs.each_key do |pack_name|
  stack = resolve_stack(pack_name, packs)
  skill_to_repo = {}
  stack.each do |stack_pack|
    repo_info = repos[stack_pack]
    next unless repo_info

    tile = repo_info[:tile]
    skills = tile['skills'] || {}
    skills.each_key do |skill_name|
      if skill_to_repo.key?(skill_name)
        puts "FAIL: Skill '#{skill_name}' is defined in both '#{stack_pack}' (#{repo_info[:name]}) and '#{skill_to_repo[skill_name]}'"
        all_passed = false
      else
        skill_to_repo[skill_name] = stack_pack
      end
    end
  end
end

# 5. Every agent's dependencies are resolvable
puts "\n--- Check 5: Agent Dependencies Resolution ---"
repos.each do |pack_name, repo_info|
  agents_json_path = File.join(repo_info[:path], 'agents.json')
  next unless File.exist?(agents_json_path)

  begin
    agents_data = JSON.parse(File.read(agents_json_path))
  rescue StandardError => e
    puts "FAIL: Failed to parse agents.json for '#{pack_name}': #{e.message}"
    all_passed = false
    next
  end

  agents = agents_data['agents'] || {}
  agents.each do |agent_name, agent_info|
    agent_path = File.join(repo_info[:path], agent_info['path'])
    unless File.exist?(agent_path)
      puts "FAIL: Agent '#{agent_name}' in '#{pack_name}' has missing SKILL.md at #{agent_path}"
      all_passed = false
      next
    end

    content = File.read(agent_path)
    match = content.match(/\A---\s*\n(.*?)\n---/m)
    unless match
      puts "FAIL: Agent '#{agent_name}' in '#{pack_name}' has no YAML front-matter in SKILL.md"
      all_passed = false
      next
    end

    begin
      front_matter = YAML.safe_load(match[1])
    rescue StandardError => e
      puts "FAIL: Agent '#{agent_name}' in '#{pack_name}' has invalid YAML front-matter: #{e.message}"
      all_passed = false
      next
    end

    metadata = front_matter['metadata'] || {}
    dependencies = metadata['dependencies'] || []
    if dependencies.is_a?(Array)
      dependencies.each do |dep|
        next unless dep.is_a?(Hash)
        source = dep['source']
        skills = dep['skills'] || []

        target_repo_info = nil
        if source == 'self' || source == repo_info[:name] || source == pack_name
          target_repo_info = repo_info
        else
          target_repo_info = repos.values.find { |r| r[:name] == source || r[:name].split('/').last == source.split('/').last }
        end

        if target_repo_info.nil?
          puts "FAIL: Agent '#{agent_name}' in '#{pack_name}' depends on unknown source '#{source}'"
          all_passed = false
          next
        end

        target_skills = target_repo_info[:tile]['skills'] || {}
        skills.each do |skill_name|
          unless target_skills.key?(skill_name)
            puts "FAIL: Agent '#{agent_name}' in '#{pack_name}' depends on skill '#{skill_name}' from '#{source}', but it is not defined in that source's tile.json"
            all_passed = false
          end
        end
      end
    else
      puts "FAIL: Agent '#{agent_name}' in '#{pack_name}' has invalid 'dependencies' in YAML front-matter (must be a list)"
      all_passed = false
    end
  end
end

puts "\n========================================="
if all_passed
  puts "AUDIT STATUS: PASS"
  exit 0
else
  puts "AUDIT STATUS: FAIL"
  exit 1
end
