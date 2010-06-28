
Gem::Specification.new do |s|
  s.name            = 'net-sshr'
  s.summary         = 'Simple ssh wrapper to execute commands on remote hosts'
  s.description     = 'Simple ssh wrapper to execute commands on remote hosts'
  s.requirements    = [ 'net/ssh/multi' ]
  s.version         = '0.0.1'
  s.author          = 'Gavin Carr'
  s.email           = 'gavin@openfusion.net'
  s.platform        = Gem::Platform::RUBY
  s.required_ruby_version   = '>= 1.8'
  s.files           = Dir['**/**']
  s.executables     = 'sshr'
  s.test_files      = Dir['test/test*.rb']
  s.has_rdoc        = false
end

