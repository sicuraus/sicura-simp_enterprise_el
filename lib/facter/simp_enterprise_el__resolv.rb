# frozen_string_literal: true

# @summary Collect information for compliance checks

Facter.add('simp_enterprise_el__resolv') do
  confine kernel: 'Linux'

  setcode do
    retval = {}

    begin
      nameserver_list = File.readlines('/etc/resolv.conf').grep(%r{^nameserver\b})
    rescue => error
      p error.message
    end
    nameserver_list&.map! { |e| e.split.last }
    retval['nameservers'] = nameserver_list
    retval
  end
end
