require 'test_helper'

class TestKickstartProvision < MiniTest::Test
  include TemplatesHelper

  def validate_distro(template, family, name, major, minor, ksversion)
    ns = FakeNamespace.new(family, name, major, minor)
    code, output = validate_erb(template, ns, ksversion)
    assert_empty output
    assert_equal code, 0
  end

  def validate_template(template, major, minor, hostgroup = 'base')
    ns = FakeNamespace.new('Redhat', 'RHEL', major, minor, hostgroup)
    output = render_erb(template, ns)
    print output if debug
    refute_empty output
  end

  def test_rhel_6
    validate_distro('kickstart/provision_rhel.erb', 'Redhat', 'RHEL', '6', '0', 'RHEL6')
  end

  def test_rhel_7
    validate_distro('kickstart/provision_rhel.erb', 'Redhat', 'RHEL', '7', '0', 'RHEL7')
  end

  def test_pxelinux_rhel6
    validate_template('kickstart/PXELinux.erb', '6', '8')
  end

  def test_pxelinux_rhel7
    validate_template('kickstart/PXELinux.erb', '7', '2')
  end

  def test_nfsroot_ro_owens_compute
    validate_template('pxe/PXELinux_local.erb', '7', '2', 'base/owens/compute')
  end

  def test_nfsroot_ro_owens_login
    validate_template('pxe/PXELinux_local.erb', '7', '2', 'base/owens/login')
  end

  def test_nfsroot_rw_owens
    validate_template('pxe/PXELinux_local.erb', '7', '2', 'base/owens/rw')
  end

  def test_nfsroot_ro_ruby_compute
    validate_template('pxe/PXELinux_local.erb', '6', '8', 'base/ruby/compute')
  end

  def test_nfsroot_ro_ruby_login
    validate_template('pxe/PXELinux_local.erb', '6', '8', 'base/ruby/login')
  end

  def test_nfsroot_rw_ruby
    validate_template('pxe/PXELinux_local.erb', '6', '8', 'base/ruby/rw')
  end

end
