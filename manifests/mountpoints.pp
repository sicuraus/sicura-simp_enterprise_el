# @summary Manage mount options
#
# @param removable_options Options to enforce on removable media
# @param removable Hash of mountpoints and whether or not they are removable
#
# @example
#   include simp_enterprise_el::mountpoints
class simp_enterprise_el::mountpoints (
  Hash[Stdlib::Unixpath, Array[String]]     $required_options,
  Array[String]                             $removable_options,
  Optional[Hash[Stdlib::Unixpath, Boolean]] $removable = $facts.dig('simp_enterprise_el__facts', 'removable'),
) {
  $required_options.each |$fs, $options| {
    if $facts['mountpoints'][$fs] == undef {
      notify { "${fs} is not a mount point. Can't enforce options ${$options.join(',')}.": }
    } elsif $facts['mountpoints'][$fs]['filesystem'] == 'btrfs' {
      # We can't detect bind mounts on btrfs.
      $options.each |$option| {
        unless $option in $facts['mountpoints'][$fs]['options'] {
          exec { "/bin/mount -o remount,${option} '${fs}'": }
        }
      }
    } else {
      $target = $facts.dig('simp_enterprise_el__facts', 'bind', $fs)
      if $target =~ String {
        $device = $target
        $fstype = 'none'
        $bind = ['bind']
      } else {
        $device = $facts['mountpoints'][$fs]['device']
        $fstype = $facts['mountpoints'][$fs]['filesystem']
        $bind = []
      }

      mount { $fs:
        ensure   => 'mounted',
        device   => $device,
        fstype   => $fstype,
        options  => simplib::join_mount_opts($facts['mountpoints'][$fs]['options'] + $bind, $options),
        remounts => true,
      }
    }
  }

  $removable.lest || { {} }.reduce([]) |$memo, $value| {
    if $value[1] {
      $memo + [$value[0]]
    } else {
      $memo
    }
  }.each |$mountpoint| {
    $removable_options.each |$option| {
      unless $option in $facts['mountpoints'][$mountpoint]['options'] {
        # We don't want to assume that these have entries in /etc/fstab.
        exec { "/bin/mount -o remount,${option} '${mountpoint}'": }
      }
    }
  }
}
