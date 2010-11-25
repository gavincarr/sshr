
Gem::Specification.new do |s|
  s.name            = 'net-sshr'
  s.summary         = 'Flexible ssh wrapper to execute commands on remote hosts'
  s.description     = 'Flexible ssh wrapper to execute commands on remote hosts and render the output in nice ways'
  s.add_dependency('net-ssh')
  s.add_dependency('net-ssh-multi')
  s.version         = '0.6.1'
  s.author          = 'Gavin Carr'
  s.email           = 'gavin@openfusion.net'
  s.homepage        = 'http://www.openfusion.net/tags/sshr'
  s.platform        = Gem::Platform::RUBY
  s.required_ruby_version   = '>= 1.8'
  s.files           = Dir['**/**']
  s.test_files      = Dir['test/test*.rb']
  s.executables     = 'sshr'
end

