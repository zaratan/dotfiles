# Bundler
alias b="bundle"

# Tests and Specs
alias t="bundle exec rspec"
alias cuc="bundle exec cucumber"

# Rails
alias migrate="rake db:migrate && rake db:test:prepare"
alias m="migrate"
alias rk="rake"
alias dbr="rake db:drop db:create; m"
