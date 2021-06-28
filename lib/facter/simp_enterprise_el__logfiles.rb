# frozen_string_literal: true

# @summary Collect list of log files

Facter.add('simp_enterprise_el__logfiles') do
  confine osfamily: 'RedHat'

  setcode do
    begin
      require 'find'

      retval = []

      Find.find('/var/log') do |file|
        retval << file if File.file?(file)
      end

      retval
    rescue => e
      Facter.warn(e)
      nil
    end
  end
end
