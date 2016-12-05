require 'rubygems'
gem 'minitest'
require 'minitest/autorun'
require 'minitest/reporters'
require 'erb'
require 'tempfile'
require 'yaml'

Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new

DISKLAYOUT = <<DL
zerombr
clearpart --all --initlabel
part / --fstype=ext4 --size=1024 --grow
part swap  --recommended
DL

def debug
  return true if ENV['DEBUG'] == 'true'
  return false
end

class FakeStruct
  def initialize(hash)
    hash.each do |key, value|
      singleton_class.send(:define_method, key) { value }
    end
  end

  def get_binding
    binding
  end

  def to_s
    as_string
  end

  # Roughly equivalent to HostCommon#param_true?/false in Foreman core
  def param_true?(name)
    params[name] == 'true'
  end

  def param_false?(name)
    params[name] == 'false'
  end
end

module TemplatesHelper
  def render_erb(template, namespace)
    namespace.template_name = template
    erb = ::ERB.new(IO.read(template), nil, '-')
    erb.filename = template
    erb.result(namespace.instance_eval { binding })
  end

  def ksvalidator(version, kickstart)
    ksvalidator_cmd = ENV['KSVALIDATOR'] || 'ksvalidator'
    output = `#{ksvalidator_cmd} -v #{version} #{kickstart}`
    [$?.to_i, output]
  end

  def validate_erb(template, namespace, ksversion)
    t = Tempfile.new('community-templates-validate')
    t.write(render_erb(template, namespace))
    t.close
    ksvalidator(ksversion, t.path)
  ensure
    t.unlink
  end

end

class FakeNamespace
  include ::TemplatesHelper
  attr_reader :root_pass, :grub_pass
  attr_accessor :template_name
  def initialize(family, name, major, minor, hostgroup = 'base', local_boot_template = 'local', local_boot_default = 'local')
    @mediapath = 'url --url http://localhost/repo/xyz'
    @root_pass = '$1$redhat$9yxjZID8FYVlQzHGhasqW/'
    @grub_pass = 'blah'
    @kernel = "boot/#{family}-#{major}.#{minor}-x86_64-vmlinuz"
    @initrd = "boot/#{family}-#{major}.#{minor}-x86_64-initrd.img"
    @dynamic = false
    @static = false
    case major
    when '7'
      kernel = '3.10.0-327.36.3.el7.x86_64'
    when '6'
      kernel = '2.6.32-573.35.2.el6.x86_64'
    when '5'
      kernel = '2.6.18-406.el5'
    else
      kernel = nil
    end
    @host = FakeStruct.new(
      :operatingsystem => FakeStruct.new(
        :name => name,
        :family => family,
        :major => major,
        :minor => minor,
        :as_string => name
      ),
      :architecture => 'x86_64',
      :diskLayout => DISKLAYOUT,
      :puppetmaster => 'http://localhost',
      :params => {
        'enable-puppetlabs-repo' => 'true',
        'nfsroot_kernel_version' => kernel,
        'local_boot_template' => local_boot_template,
        'local_boot_default' => local_boot_default
      },
      :info => {
        'parameters' => { 'realm' => 'EXAMPLE.COM' }
      },
      :otp => 'onetimepassword',
      :realm => FakeStruct.new(
        :name => 'EXAMPLE.COM',
        :realm_type => 'FreeIPA',
        :as_string  => 'EXAMPLE.COM'
      ),
      :as_string => name,
      :subnet => FakeStruct.new(
        :dhcp_boot_mode? => true,
        :dhcp? => true,
      ),
      :mac => '00:00:00:00:00:01',
      :provision_interface => FakeStruct.new(
        :type => 'Nic::Managed',
      ),
      :primary_interface => FakeStruct.new(
        :type => 'Nic::Managed',
      ),
      :managed_interfaces => [],
      :bond_interfaces => [],
      :provider => 'BareMetal',
      :hostgroup => FakeStruct.new(
        :name => hostgroup,
        :as_string => hostgroup,
      ),
      :puppet_ca_server => 'puppet',
      :certname => name,
      :name => name,
      :environment => FakeStruct.new(
        :name => 'production',
        :as_string => 'production',
      ),
      :build? => false
    )
  end

  def snippet(snip)
    test_dir = File.dirname(__FILE__)
    root = File.absolute_path("#{test_dir}/../")
    Dir.glob("#{root}/**/*.erb") do |erb|
      extracted = IO.read(erb).match(/<%#(.+?).-?%>/m)
      yaml = YAML.load(extracted[1])
      next if yaml['kind'] != 'snippet'
      if yaml['name'] == snip
        return render_erb(erb, self)
      end
    end
  end

  def ks_console(*args)
    'console=ttyS99'
  end

  def foreman_url(*args)
    'http://localhost'
  end
end

class String
  def blank?
    self !~ /[^[:space:]]/
  end
end

# Pulled from Rails source
class Object
  def present?
    !blank?
  end

  def blank?
    respond_to?(:empty?) ? !!empty? : !self
  end
end
