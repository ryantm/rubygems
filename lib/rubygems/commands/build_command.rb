# frozen_string_literal: true
require 'rubygems/command'
require 'rubygems/package'
require 'rubygems/version_option'

class Gem::Commands::BuildCommand < Gem::Command
  include Gem::VersionOption

  def initialize
    super 'build', 'Build a gem from a gemspec'

    add_platform_option

    add_option '--force', 'skip validation of the spec' do |value, options|
      options[:force] = true
    end

    add_option '--strict', 'consider warnings as errors when validating the spec' do |value, options|
      options[:strict] = true
    end

    add_option '-o', '--output FILE', 'output gem with the given filename' do |value, options|
      options[:output] = value
    end

    add_option '-C PATH', '', 'Run as if gem build was started in <PATH> instead of the current working directory.' do |value, options|
      options[:build_path] = value
    end
  end

  def arguments # :nodoc:
    "GEMSPEC_FILE  gemspec file name to build a gem for"
  end

  def description # :nodoc:
    <<-EOF
The build command allows you to create a gem from a ruby gemspec.

The best way to build a gem is to use a Rakefile and the Gem::PackageTask
which ships with RubyGems.

The gemspec can either be created by hand or extracted from an existing gem
with gem spec:

  $ gem unpack my_gem-1.0.gem
  Unpacked gem: '.../my_gem-1.0'
  $ gem spec my_gem-1.0.gem --ruby > my_gem-1.0/my_gem-1.0.gemspec
  $ cd my_gem-1.0
  [edit gem contents]
  $ gem build my_gem-1.0.gemspec

Gems can be saved to a specified filename with the output option:

  $ gem build my_gem-1.0.gemspec --output=release.gem

    EOF
  end

  def usage # :nodoc:
    "#{program_name} GEMSPEC_FILE"
  end

  def execute
    gem_name = get_one_optional_argument || find_gemspec
    build_gem(gem_name)
  end

  private

  def find_gemspec
    gemspecs = Dir.glob("*.gemspec").sort

    if gemspecs.size > 1
      alert_error "Multiple gemspecs found: #{gemspecs}, please specify one"
      terminate_interaction(1)
    end

    gemspecs.first
  end

  def build_gem(gem_name)
    gemspec = File.extname(gem_name) == ".gemspec" ? gem_name : "#{gem_name}.gemspec"

    if File.exist?(gemspec)
      spec = Gem::Specification.load(gemspec)

      if options[:build_path]
        Dir.chdir(File.dirname(gemspec)) do
          spec = Gem::Specification.load(File.basename(gemspec))
          build_package(spec)
        end
      else
        build_package(spec)
      end

    else
      alert_error "Gemspec file not found: #{gemspec}"
      terminate_interaction(1)
    end
  end

  def build_package(spec)
    if spec
      Gem::Package.build(
        spec,
        options[:force],
        options[:strict],
        options[:output]
      )
    else
      alert_error "Error loading gemspec. Aborting."
      terminate_interaction 1
    end
  end
end
