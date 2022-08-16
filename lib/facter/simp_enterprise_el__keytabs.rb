# frozen_string_literal: true

# @summary Collect list of log files

Facter.add('simp_enterprise_el__keytabs') do
  confine kernel: 'Linux'

  setcode do
    begin
      Dir.glob('/etc/*.keytab')
    rescue => e
      Facter.warn(e)
      nil
    end
  end
end
