# frozen_string_literal: true

# @summary Collect list of bootloader files: the known GRUB files and, on EL10 and later,
#   every other regular file directly in /boot/grub2

Facter.add('simp_enterprise_el__grub') do
  confine :os do |os|
    os['family'] == 'RedHat'
  end

  setcode do
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

    # The EL10 CIS benchmarks check every regular file directly in /boot/grub2,
    # not only the ones above (BIOS installs keep device.map there, at 0644).
    # EL8 and EL9 check only the files above, so the scan is confined to EL10
    # and later; Fedora and Amazon Linux, whose major releases are also 10 or
    # above, aren't covered by those benchmarks and are left out.
    # The scanned files get no ensure: some come and go (grubenv.new,
    # *.rpmsave), and one removed after facts were collected must not be
    # recreated. A failed scan keeps the files collected above.
    os = Facter.value(:os).to_h
    if os.dig('release', 'major').to_i >= 10 && !['Fedora', 'Amazon'].include?(os['name']) &&
       retval.dig('/boot/grub2', 'ensure') == 'directory'
      begin
        Dir.children('/boot/grub2').sort.each do |name|
          file = File.join('/boot/grub2', name)
          next if retval.key?(file)
          next if File.symlink?(file) || !File.file?(file)

          retval[file] = {}
        end
      rescue SystemCallError => e
        Facter.warn("simp_enterprise_el__grub: cannot scan /boot/grub2: #{e.message}")
      end
    end

    retval
  rescue => e
    Facter.warn(e)
    nil
  end
end
