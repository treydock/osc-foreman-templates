gem 'minitest'
require 'minitest/autorun'
require 'test_helper'

class TestKickstartProvision < MiniTest::Unit::TestCase
  include TemplatesHelper

  def validate_distro(template, family, name, major, minor, ksversion)
    ns = FakeNamespace.new(family, name, major, minor)
    code, output = validate_erb(template, ns, ksversion)
    assert_empty output
    assert_equal code, 0
  end

  def test_rhel_6
    validate_distro('kickstart/provision_rhel.erb', 'Redhat', 'RHEL', '6', '0', 'RHEL6')
  end

  def test_rhel_7
    validate_distro('kickstart/provision_rhel.erb', 'Redhat', 'RHEL', '7', '0', 'RHEL7')
  end
end
