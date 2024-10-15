# frozen_string_literal: true

# @summary Collect information for compliance checks

Facter.add('simp_enterprise_el__mounts') do
  confine kernel: 'Linux'

  setcode do
    retval = {}
    mountpoints = Facter.value('mountpoints')

    mountpoints.each do |key, value|
      next unless value['filesystem'].match?(%r{^nfs[34]?$})

      retval['nfs_mount'] = {} if retval['nfs_mount'].nil?
      retval['nfs_mount'][key] = value['options'].reject { |option| option.start_with?('vers=') }
    end

    mountpoints.each do |key, value|
      # btrfs subvolumes are listed in findmnt output the same way as bind mounts
      next if value['filesystem'] == 'btrfs'

      fsroot = Facter::Core::Execution.execute("findmnt -n -o fsroot '#{key}'", on_fail: nil)&.chomp
      next if fsroot.nil?
      next if fsroot == '/'

      retval['bind'] = {} if retval['bind'].nil?
      retval['bind'][key] = fsroot
    end

    mountpoints.each do |key, value|
      next if value['device'].nil?
      next unless value['device'].start_with?('/dev/')

      device = value['device'].delete_prefix('/dev/')

      def removable(path)
        File.read("#{path}/removable").chomp.to_i.positive?
      end

      if Dir.exist?("/sys/block/#{device}")
        retval['removable'] = {} if retval['removable'].nil?
        retval['removable'][key] = removable("/sys/block/#{device}")
        next
      end

      Dir.glob("/sys/block/*/#{device}").each do |p|
        retval['removable'] = {} if retval['removable'].nil?
        retval['removable'][key] = removable(p.delete_suffix("/#{device}"))
        break
      end
    end

    retval
  rescue => e
    Facter.warn(e)
    nil
  end
end
