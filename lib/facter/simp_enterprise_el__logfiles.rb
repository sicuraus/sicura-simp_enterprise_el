# frozen_string_literal: true

# @summary Collect list of log files

Facter.add('simp_enterprise_el__logfiles') do
  confine :os do |os|
    os['family'] == 'RedHat'
  end

  setcode do
    require 'find'

    retval = {}

    Find.find('/var/log') do |file|
      next unless File.file?(file)

      sb = File::Stat.new(file)
      retval[file] = {
        'mode' => '0' + (sb.mode & 0o777).to_s(8),
      }
    end

    retval
  rescue => e
    Facter.warn(e)
    nil
  end
end
