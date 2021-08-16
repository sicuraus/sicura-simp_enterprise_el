# frozen_string_literal: true

# @summary Collect list of bootloader files

Facter.add('simp_enterprise_el__grub') do
  confine osfamily: 'RedHat'

  setcode do
    begin
      retval = {}

      [
        '/boot/grub2',
        '/boot/grub2/grub.cfg',
        '/boot/grub2/user.cfg',
        '/boot/grub2/grubenv',
      ].each do |file|
        next unless File.exist?(file)
        next if File.symlink?(file)

        retval[file] = {
          'ensure' => Dir.exist?(file) ? 'directory' : 'file',
        }
      end

      retval
    rescue => e
      Facter.warn(e)
      nil
    end
  end
end
