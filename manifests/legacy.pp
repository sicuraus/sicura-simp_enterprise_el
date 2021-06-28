# @summary Remove legacy `+` entries in passwd, group, and shadow files
#
# @param passwd Manage /etc/passwd
# @param group Manage /etc/group
# @param shadow Manage /etc/shadow
#
# @example
#   include simp_enterprise_el::legacy
class simp_enterprise_el::legacy (
  Boolean $passwd = false,
  Boolean $group  = false,
  Boolean $shadow = false,
) {
  $noop = { 'noop' => true }
  $files = {
    '/etc/passwd' => $passwd ? {
      true    => {},
      default => $noop,
    },
    '/etc/group' => $group ? {
      true    => {},
      default => $noop,
    },
    '/etc/shadow' => $shadow ? {
      true    => {},
      default => $noop,
    },
  }

  $files.each |$file, $options| {
    file_line { "${file}-legacy":
      ensure            => absent,
      path              => $file,
      match             => '^\\+:',
      match_for_absence => true,
      *                 => $options,
    }
  }
}
