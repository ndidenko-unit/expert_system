# frozen_string_literal: true

def shutdown
  puts 'Shutting down gracefully...'
  exit(false)
end

def welcome
  puts "\033[31mWelcome to this interactive Expert System."
  puts 'Type "help" to print a list of available commands.'
  puts 'By default, all facts are false, and can only be made true'
  puts "by the initial facts statement, or by application of a rule.\033[0m"
end

def print_help
  puts '====================================== COMMANDS ======================================='
  puts '#                                                                                     #'
  puts '#    run   [file path]               : load a file and run it. Reset all facts        #'
  puts '#                                                                                     #'
  puts '#    fact  [letter] = [true/false]   : set the fact statement (not saved !)           #'
  puts '#    save                            : save the new facts and reevaluate the rules    #'
  puts '#    query [letters]                 : print the fact(s) corresponding                #'
  puts '#                                                                                     #'
  puts '#    rules                           : print all rules                                #'
  puts '#    facts                           : print all saved facts                          #'
  puts '#    facts:statement                 : print all facts statements                     #'
  puts '#    reset                           : reset all facts and rules                      #'
  puts '#    exit                            : exit the program                               #'
  puts '#                                                                                     #'
  puts '======================================================================================='
end

def run_engine_expression(expression)
  expression[0] = expression[0].match(/\([A-Z]/) ? expression[0].gsub(/([A-Z])/, 'fact_array["\1"] == true') : expression[0].gsub(/([^!])([A-Z])/, ' fact_array["\2"] == true')
  expression[0] = expression[0].gsub(/(!)([A-Z])/, 'fact_array["\2"] == false')
  expression[2] = expression[2].match(/\([A-Z]/) ? expression[2].gsub!(/([A-Z])/, 'fact_array["\1"] == true') : expression[2].gsub!(/([^!])([A-Z])/, ' fact_array["\2"] = true')
  expression[2] = expression[2].gsub(/(!)([A-Z])/, 'fact_array["\2"] = false')
  expression.map do |e|
    e.gsub!('+', '&&')
  end
  expression.map do |e|
    e.gsub!('|', '||')
  end
  expression.map {|e| e.gsub!(/(fact_array\["[A-Z]"\] == (true|false))/, '(\1)') if e.match(/\(?fact_array\["[A-Z]"\] == (true|false)\s+\^\s+fact_array\["[A-Z]"\] == (true|false)\)?/)}
  expression
end
