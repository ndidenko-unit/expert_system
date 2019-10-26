# frozen_string_literal: true

require_relative 'methods.rb'

Signal.trap('INT') do
  shutdown
  exit(false)
end

Signal.trap('TERM') do
  shutdown
  exit(false)
end

define_method :clear_all do |fact_array, rules_to_code, fact_statement, rules|
  rules_to_code.clear
  rules.clear
  fact_statement.clear
  ('A'..'Z').each { |c| fact_array.store(c, false) }
end

define_method :run_expression do |rules_to_code, index|
  begin
    eval "if #{rules_to_code[index][0]}\n#{rules_to_code[index][2]} end"
    if rules_to_code[index][1] == '<=>'
      rules_to_code[index][0] = rules_to_code[index][0].gsub(/\==/, '=')
      rules_to_code[index][2] = rules_to_code[index][2].gsub(/\=/, '==')
      eval "if #{rules_to_code[index][2]}\n#{rules_to_code[index][0]} end"
    end
  rescue Exception => e
    puts "Rule #{index + 1}: syntax error"
    false
  end
  true
end

define_method :engine do |rules_to_code|
  i = 1
  rules_to_code.each do
    rules_to_code.each_with_index do |_line, index|
      if index < i
        return false unless run_expression(rules_to_code, index)
      else
        break
      end
    end
    if i == rules_to_code.size && i > 1
      rules_to_code.each_with_index { |_line, index| run_expression(rules_to_code, index) }
   end
    i += 1
  end
  true
end

define_method :run_engine do |filename, fact_array, rules_to_code, fact_statement, rules|
  clear_all(fact_array, rules_to_code, fact_statement, rules)
  file = File.open(filename)
  read = file.read
  read.gsub!(/#.*$/, '')
  read.split('').each do |c|
    next if c.match(/[A-Z()!?+^|=<>\s*\t*\n+]/)

    puts 'Unknow character present'
    file.close
    return
  end
  if !read.match(/^=[A-Z]*\s*$/)
    puts 'Facts: syntax error'
    file.close
    return
  elsif read.match(/^\?\s*$/)
    puts 'Queries: none'
    file.close
    return
  elsif !read.match(/^\?[A-Z]+\s*$/)
    puts 'Queries: syntax error'
    file.close
    return
  end
  if facts = read.match(/^=[A-Z]+\s*$/).to_s
    ('A'..'Z').each { |c| fact_array[c] = true if facts.include? c }
  else
    facts = ''
  end
  fact_statement = facts.empty? ? '' : facts.gsub!(/[\=\n]/, '').split('').each { |fact| fact_statement << fact }
  read.each_line { |line| rules.push(line) if line.match(/^\(?!?[A-Z]/) }
  if rules.any?
    duplicates = rules.each_with_object([]) do |e, a|
      a << e if rules.count(e) > 1
    end
    if duplicates.any?
      puts 'Rules: duplicates expression'
      clear_all(fact_array, rules_to_code, fact_statement, rules)
      file.close
      return
    end
    rules_error = false
    rules.each_with_index do |line, index|
      if !line.match(/^\(?!?[A-Z]\s+([+|^]|=>|<=>)\s+\(?!?[A-Z]\)?/) || line.match(/[A-Z]\s*[A-Z]/) \
      || line.match(/([+|^]|=>|<=>)\s*([+|^]|=>|<=>)/)
        clear_all(fact_array, rules_to_code, fact_statement, rules)
        file.close
        puts "Rule #{index + 1}: syntax error"
        return
      else
        expression = line.gsub!(/^/, ' ').split(/(=>|<=>)/)
        if expression.to_s.count('(') != expression.to_s.count(')')
          clear_all(fact_array, rules_to_code, fact_statement, rules)
          rules_error = true
          puts "Rule #{index + 1}: parentheses not properly closed"
          break
        elsif expression[2].match(/[\||^]/)
          clear_all(fact_array, rules_to_code, fact_statement, rules)
          rules_error = true
          puts "Rule #{index + 1}: ambiguous ruleset \"" + expression[1] + ' ' + expression[2].strip + '"'
          break
        else
          rules_to_code << run_engine_expression(expression)
        end
      end
    end
  end
  unless rules_error
    unless engine(rules_to_code)
      clear_all(fact_array, rules_to_code, fact_statement, rules)
      return
    end
    if queries = read.match(/^\?[A-Z]+\s*$/).to_s
      puts queries.strip
      ('A'..'Z').each do |c|
        puts "#{c} = " + fact_array[c].to_s if queries.include? c
      end
    end
  end
  file.close
  return
end

fact_array = {}
('A'..'Z').each { |c| fact_array.store(c, false) }
welcome
time = Time.now.getutc.strftime('%H:%M:%S')
print "\033[33m#{time} [No file loaded] >> \033[0m"
rules = []
noFile = true
filename = ''
fact_statement = []
rules_to_code = []
while input = $stdin.gets
  input ||= ''
  input = input.chomp
  args = input.split(' ')
  if input.match(/^exit\s*$/)
    shutdown
  elsif input.match(/^reset\s*$/)
    clear_all(fact_array, rules_to_code, fact_statement, rules)
    noFile = true
    puts 'Cleared'
  elsif input.match(/^rules\s*$/)
    if rules.empty?
      puts 'Rules: none'
    else
      rules.each { |rule| puts rule.strip }
    end
  elsif input.match(/^fact\s+[A-Za-z]+\s+=\s+(true|false)\s*$/)
    if args[3] == 'true'
      args[1].split('').each do |letter|
        is_fact = false
        fact_statement.each { |fact| is_fact = true if fact == letter.upcase }
        fact_statement << letter.upcase unless is_fact
      end
    else
      args[1].split('').each do |letter|
        fact_statement.each do |fact|
          fact_statement.delete(fact) if fact == letter.upcase
        end
      end
    end
    puts 'Success'
  elsif input.match(/^save\s*$/)
    if rules_to_code.empty?
      puts 'Rules: none'
    else
      ('A'..'Z').each { |c| fact_array.store(c, false) }
      fact_statement.each { |fact| fact_array.store(fact, true) }
      engine(rules_to_code)
      puts 'Saved and reevaluated'
    end
  elsif input.match(/^facts\s*$/)
    fact_array.each do |key, value|
      puts "#{key} = #{value}"
    end
  elsif input.match(/^facts:statement\s*$/)
    puts '=' + fact_statement.join(',').gsub(',', '').chars.sort.join
  elsif input.match(/^query\s+[A-Za-z]+\s*$/)
    args[1].split('').each { |letter| puts letter.upcase + ' = ' + fact_array[letter.upcase].to_s }
  elsif input.match(/^help\s*$/)
    print_help
  elsif input.match(/^run\s+.+\s*$/)
    filename = args[1]
    if !File.file?(filename)
      puts filename + ' is not a file.'
    elsif !File.readable?(filename)
      puts filename + ': permission denied'
    elsif File.zero?(filename)
      puts filename + ' is empty.'
    else
      run_engine(filename, fact_array, rules_to_code, fact_statement, rules)
      noFile = rules.empty? ? true : false
    end
  else
    puts 'Unknown command'
  end
  time = Time.now.getutc.strftime('%H:%M:%S')
  print "\033[33m#{time} "
  if noFile
    print '[No file loaded]'
  else
    print '[' + filename + ']'
   end
  print " >> \033[0m"
end
