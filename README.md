# expert_system

```ruby expert_system.rb```  => run [path/to/file]

<h4>File example:</h4>

```
B => A               # if B(true) then A(true)
D + E => B           # if D and E then A
!G + H => !F         # if G(false) and H(true) then F(false)
I + J => G
G <=> H              # biconditional rule: if G then H but also if H then G
L | M => K           # if A or M ...
L ^ M => K           # if A xor M ...
O + P => L | N       # ambiguous: L or N are undetermined
N => M
(F | G) + H => E     # parentheses handling

=DEIJOP              # By default, all facts are false, and can only be made true by this initial facts statement.

?AFKP                # list of queries
```

<h4>"help" for a list of available commands:</h4>

```
====================================== COMMANDS =======================================
#                                                                                     #
#    run   [file path]               : load a file and run it. Reset all facts        #
#                                                                                     #
#    fact  [letter] = [true/false]   : set the fact statement (not saved !)           #
#    save                            : save the new facts and reevaluate the rules    #
#    query [letters]                 : print the fact(s) corresponding                #
#                                                                                     #
#    rules                           : print all rules                                #
#    facts                           : print all saved facts                          #
#    facts:statement                 : print all facts statements                     #
#    reset                           : reset all facts and rules                      #
#    quit                            : exit the program                               #
#                                                                                     #
=======================================================================================
```
