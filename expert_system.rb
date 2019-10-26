def shutdown
	puts "Shutting down gracefully..."
	exit(false)
end

Signal.trap("INT") { 
  shutdown 
  exit(false)
}

Signal.trap("TERM") {
  shutdown
  exit(false)
}

define_method :clearAll do | factArray, rulesToCode, factStatement, rules |
	rulesToCode.clear
  rules.clear
	factStatement.clear
	('A'..'Z').each { |c| factArray.store(c, false) }
end

define_method :runExpression do |rulesToCode, index|
	begin
		eval "if #{rulesToCode[index][0]}\n#{rulesToCode[index][2]} end"
		if rulesToCode[index][1] == "<=>"
			rulesToCode[index][0] = rulesToCode[index][0].gsub(/\==/, '=')
			rulesToCode[index][2] = rulesToCode[index][2].gsub(/\=/, '==')
			eval "if #{rulesToCode[index][2]}\n#{rulesToCode[index][0]} end"
		end	
	rescue Exception => e
		puts "Rule #{index + 1}: syntax error"
		false
	end
	true
end

define_method :engine do |rulesToCode|
	i = 1
	rulesToCode.each_with_index do |line, index|
		rulesToCode.each_with_index do |line, index|
			if index < i
					return false unless runExpression(rulesToCode, index)
			else
				break
			end
		end
		rulesToCode.each_with_index {|line, index| runExpression(rulesToCode, index) } if i == rulesToCode.size && i > 1
		i += 1
	end
	true
end

define_method :runEngine do |filename, factArray, rulesToCode, factStatement, rules|
	clearAll(factArray, rulesToCode, factStatement, rules)
	file = File.open(filename)
	read = file.read
	read.gsub!(/#.*$/, '')
	read.split('').each do |c|
		unless c.match(/[A-Z()!?+^|=<>\s*\t*\n+]/)
			puts "Unknow character present"
			file.close
			return
		end
	end
	if !read.match(/^=[A-Z]*\s*$/)
		puts "Facts: syntax error"
		file.close
		return
	elsif read.match(/^\?\s*$/)
		puts "Queries: none"
		file.close
		return
	elsif !read.match(/^\?[A-Z]+\s*$/)
		puts "Queries: syntax error"
		file.close
		return
	end
	if facts = read.match(/^=[A-Z]+\s*$/).to_s
		('A'..'Z').each {|c| factArray[c] = true if facts.include? c }
	else
		facts = ""
  end
	factStatement = facts.empty? ? "" : facts.gsub!(/[\=\n]/, '').split('').each { |fact| factStatement << fact }
	read.each_line {|line| rules.push(line) if line.match(/^\(?!?[A-Z]/)}
	if rules.any?
		duplicates = rules.each_with_object([]) { |e, a| a << e if rules.count(e) > 1 }
		if duplicates.any?
			puts "Rules: duplicates expression"
			clearAll(factArray, rulesToCode, factStatement, rules)
			file.close
			return 
		end
		rulesError = false
		rules.each_with_index do |line, index|
			if !line.match(/^\(?!?[A-Z]\s+([+|^]|=>|<=>)\s+\(?!?[A-Z]\)?/) or line.match(/[A-Z]\s*[A-Z]/) \
			or line.match(/([+|^]|=>|<=>)\s*([+|^]|=>|<=>)/)
				clearAll(factArray, rulesToCode, factStatement, rules)
				file.close
				puts "Rule #{index + 1}: syntax error"
				return
			else
				expression = line.gsub!(/^/, ' ').split(/(=>|<=>)/)
				if expression.to_s.count("(") != expression.to_s.count(")")
					clearAll(factArray, rulesToCode, factStatement, rules)
					rulesError = true
					puts "Rule #{index + 1}: parentheses not properly closed"
					break
				elsif expression[2].match(/[\||^]/)
					clearAll(factArray, rulesToCode, factStatement, rules)
					rulesError = true
					puts "Rule #{index + 1}: ambiguous ruleset \"" + expression[1] + " " + expression[2].strip + "\""
					break
        else
					expression[0] = expression[0].match(/\([A-Z]/) ? expression[0].gsub(/([A-Z])/, 'factArray["\1"] == true') : expression[0].gsub(/([^!])([A-Z])/, ' factArray["\2"] == true')
					expression[0] = expression[0].gsub(/(!)([A-Z])/, 'factArray["\2"] == false')
					expression[2] = expression[2].match(/\([A-Z]/) ? expression[2].gsub!(/([A-Z])/, 'factArray["\1"] == true') : expression[2].gsub!(/([^!])([A-Z])/, ' factArray["\2"] = true')
					expression[2] = expression[2].gsub(/(!)([A-Z])/, 'factArray["\2"] = false')
					expression.map do |e|
            e.gsub!("+", "&&")
          end
					expression.map do |e|
            e.gsub!("|", "||")
          end
					expression.map {|e| e.gsub!(/(factArray\["[A-Z]"\] == (true|false))/, '(\1)') if e.match(/\(?factArray\["[A-Z]"\] == (true|false)\s+\^\s+factArray\["[A-Z]"\] == (true|false)\)?/)}
					rulesToCode << expression
				end
			end
		end
	end
	unless rulesError
		unless engine(rulesToCode)
			clearAll(factArray, rulesToCode, factStatement, rules)
			return
		end
		if queries = read.match(/^\?[A-Z]+\s*$/).to_s
			puts queries.strip
			('A'..'Z').each { |c| puts "#{c} = " + factArray[c].to_s if queries.include? c }
		end
	end
	file.close
	return
end

factArray = {}
('A'..'Z').each { |c| factArray.store(c, false) }
puts "\033[31mWelcome to this interactive Expert System."
puts "Type \"help\" to print a list of available commands."
puts "By default, all facts are false, and can only be made true"
puts "by the initial facts statement, or by application of a rule.\033[0m"
time = Time.now.getutc.strftime("%H:%M:%S")
print "\033[33m#{time} [No file loaded] >> \033[0m"
rules = []
noFile = true
filename = ""
factStatement = []
rulesToCode = []
while input = $stdin.gets
	input ||= ""
	input = input.chomp
	args = input.split(' ')
	if input.match(/^quit\s*$/)
		shutdown
	elsif input.match(/^reset\s*$/)
		clearAll(factArray, rulesToCode, factStatement, rules)
		noFile = true
		puts "Cleared"
	elsif input.match(/^rules\s*$/)
		if rules.empty?
			puts "Rules: none"
		else
			rules.each { |rule| puts rule.strip }
		end
	elsif input.match(/^fact\s+[A-Za-z]+\s+=\s+(true|false)\s*$/)
		if args[3] == "true"
			args[1].split('').each do |letter|
				isFact = false
				factStatement.each { |fact| isFact = true if fact == letter.upcase}
				factStatement << letter.upcase unless isFact
			end
		else
			args[1].split('').each do |letter|
				factStatement.each {|fact| factStatement.delete(fact) if fact == letter.upcase }
			end
		end
		puts "Success"
	elsif input.match(/^save\s*$/)
		if rulesToCode.empty?
			puts "Rules: none"
		else
			('A'..'Z').each { |c| factArray.store(c, false) }
			factStatement.each {|fact| factArray.store(fact, true)}
			engine(rulesToCode)
			puts "Saved and reevaluated"
		end
	elsif input.match(/^facts\s*$/)
		factArray.each do |key, value|
      puts "#{key} = #{value}"
    end
	elsif input.match(/^facts:statement\s*$/)
		puts "=" + factStatement.join(',').gsub(',', '').chars.sort.join
	elsif input.match(/^query\s+[A-Za-z]+\s*$/)
		args[1].split('').each {|letter| puts letter.upcase + " = " + factArray[letter.upcase].to_s }
	elsif input.match(/^help\s*$/)
		puts "====================================== COMMANDS ======================================="
		puts "#                                                                                     #"
		puts "#    run   [file path]               : load a file and run it. Reset all facts        #"
		puts "#                                                                                     #"
		puts "#    fact  [letter] = [true/false]   : set the fact statement (not saved !)           #"
		puts "#    save                            : save the new facts and reevaluate the rules    #"
		puts "#    query [letters]                 : print the fact(s) corresponding                #"
		puts "#                                                                                     #"
		puts "#    rules                           : print all rules                                #"
		puts "#    facts                           : print all saved facts                          #"
		puts "#    facts:statement                 : print all facts statements                     #"
		puts "#    reset                           : reset all facts and rules                      #"
		puts "#    quit                            : exit the program                               #"
		puts "#                                                                                     #"
		puts "======================================================================================="
	elsif input.match(/^run\s+.+\s*$/)
		filename = args[1]
		if !File.file?(filename)
			puts filename + " is not a file."
		elsif !File.readable?(filename)
			puts filename + ": permission denied"
		elsif File.zero?(filename)
			puts filename + " is empty."
		else
			runEngine(filename, factArray, rulesToCode, factStatement, rules)
			noFile = rules.empty? ? true : false
		end
	else
		puts "Unknown command"
	end
	time = Time.now.getutc.strftime("%H:%M:%S")
	print "\033[33m#{time} "
	unless noFile
		print "[" + filename + "]"
	else
		print "[No file loaded]"
	end
	print " >> \033[0m"
end
