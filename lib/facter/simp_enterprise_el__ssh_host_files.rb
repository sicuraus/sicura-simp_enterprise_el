# frozen_string_literal: true

# @summary Collect list of ssh host key files

Facter.add('simp_enterprise_el__ssh_host_files') do
  confine kernel: 'Linux'
  confine { Dir.exist?('/etc/ssh') }

  setcode do
    retval = {}

    ssh_host_key_files = Dir.glob('/etc/ssh/ssh_host_*_key')
    ssh_host_pub_files = Dir.glob('/etc/ssh/ssh_host_*_key.pub')
    retval['ssh_host_key_files'] = ssh_host_key_files
    retval['ssh_host_pub_files'] = ssh_host_pub_files

    retval
  rescue => e
    Facter.warn(e)
    nil
  end
end
