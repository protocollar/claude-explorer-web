namespace :claude_data do
  desc "Import all Claude Code conversation data from ~/.claude"
  task import: :environment do
    puts "Starting Claude data import..."

    importer = ClaudeData::Importer.new
    importer.import_all

    puts "Import complete!"
    puts "  Projects: #{Project.count}"
    puts "  Sessions: #{Session.count}"
    puts "  Messages: #{Message.count}"
    puts "  Tool Uses: #{ToolUse.count}"
  end

  desc "Import a specific project by path"
  task :import_project, [ :path ] => :environment do |t, args|
    path = args[:path]
    unless path
      puts "Usage: bin/rails claude_data:import_project[/path/to/project]"
      exit 1
    end

    puts "Importing project: #{path}"
    project = ClaudeData::Importer.new.import_project(path)

    puts "Import complete!"
    puts "  Sessions: #{project.sessions.count}"
    puts "  Messages: #{project.messages.count}"
  end

  desc "Clear all imported data"
  task clear: :environment do
    puts "Clearing all Claude data..."

    ToolUse.delete_all
    Message.delete_all
    Session.delete_all
    Project.delete_all

    puts "Done!"
  end

  desc "Show import statistics"
  task stats: :environment do
    puts "Claude Explorer Statistics"
    puts "-" * 40
    puts "Projects:   #{Project.count}"
    puts "Sessions:   #{Session.count}"
    puts "  Main:     #{Session.main_sessions.count}"
    puts "  Sidechain:#{Session.sidechains.count}"
    puts "Messages:   #{Message.count}"
    puts "  User:     #{Message.user_messages.count}"
    puts "  Assistant:#{Message.assistant_messages.count}"
    puts "Tool Uses:  #{ToolUse.count}"
    puts ""
    puts "Top 10 Tools:"
    ToolUse.usage_counts.first(10).each do |tool, count|
      puts "  #{tool.ljust(20)} #{count}"
    end
  end
end
