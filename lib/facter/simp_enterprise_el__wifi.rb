# frozen_string_literal: true

# @summary Collect list of wireless interfaces

Facter.add('simp_enterprise_el__wifi') do
  confine kernel: 'Linux'

  setcode do
    retval = {}

    sysfs = '/sys/class/net'
    (Dir.entries(sysfs) - ['.', '..']).each do |interface|
      dir = "#{sysfs}/#{interface}"
      next unless Dir.exist?(dir)
      next unless Dir.exist?("#{dir}/wireless")

      retval[interface] = {}

      begin
        link_state = File.read("#{dir}/flags").chomp
        retval[interface]['link_up'] = %r{^0x1003$}.match?(link_state)
      rescue => e
        Facter.warn("Failed to read #{interface} flags: #{e}")
      end

      begin
        Dir.glob("#{dir}/phy80211/rfkill*/state").each do |state|
          retval[interface]['radio'] = {
            'state_file' => state,
            'on'         => File.read(state).chomp.to_i.positive?,
          }
          break
        end
      rescue => e
        Facter.warn("Failed to read #{interface} radio state: #{e}")
      end
    end

    retval
  rescue => e
    Facter.warn(e)
    nil
  end
end
