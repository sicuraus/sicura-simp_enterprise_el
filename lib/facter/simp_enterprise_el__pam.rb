# frozen_string_literal: true

# @summary Collect list of bootloader files

Facter.add('simp_enterprise_el__pam') do
  confine osfamily: 'RedHat'

  setcode do
    begin
      retval = {}
      targets = ['/etc/pam.d/system-auth', '/etc/pam.d/password-auth']

      targets.each do |target|
        fact_name = "#{File.basename(target)}_nullok"
        retval[fact_name] = false
        if File.exist?(target)
          retval[fact_name] = File.readlines(target).grep(%r{nullok}).any?
        end
      end

      retval
    rescue => e
      Facter.warn(e)
      nil
    end
  end
end
