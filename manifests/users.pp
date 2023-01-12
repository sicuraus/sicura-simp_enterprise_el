# @summary Check for problems with local users
#
# @param uid_min For users under this number, any required group resources will be added with `system => true`
# @param users List of local users
# @param groups List of local groups
# @param empty_shadow Enforce group change for users with `shadow` as their primary group
# @param to_lock List of local users that should be locked
# @param lock Enforce locking `to_lock` list
# @param to_expire List of local users that should have a password change forced
# @param expire Enforce expiring passwords of users in the `to_expire` list
# @param remove_uid_0 Remove any users other than `root` with UID 0
# @param duplicate_users List of duplicated usernames
# @param duplicate_uids List of duplicated UIDs
# @param remove_dups Enforce removing duplicate usernames or UIDs
# @param ruby Path to ruby executable
# @param force_shadow Set any user with a password in `/etc/passwd` to `x`
# @param nologin_shell Shell to use for accounts with no shell access
# @param sa_nologin Enforce /sbin/nologin as the login shell for system accounts
# @param sa_exclude List of system accounts allowed to have an login shell
#
# @example
#   include simp_enterprise_el::users
class simp_enterprise_el::users (
  Boolean         $empty_shadow,
  Boolean         $lock,
  Boolean         $expire,
  Boolean         $remove_uid_0,
  Boolean         $remove_dups,
  Boolean         $force_shadow,
  Boolean         $sa_nologin,
  String          $nologin_shell,
  Array           $sa_exclude,
  Integer[0]      $uid_min          = Integer($facts['uid_min'].lest || { 1000 }),
  Optional[Array] $users            = $facts.dig('simp_enterprise_el__facts', 'users'),
  Optional[Array] $groups           = $facts.dig('simp_enterprise_el__facts', 'groups'),
  Optional[Array] $to_lock          = $facts.dig('simp_enterprise_el__facts', 'lock'),
  Optional[Array] $to_expire        = $facts.dig('simp_enterprise_el__facts', 'expire'),
  Optional[Hash]  $duplicate_users  = $facts.dig('simp_enterprise_el__facts', 'dups', 'username'),
  Optional[Hash]  $duplicate_uids   = $facts.dig('simp_enterprise_el__facts', 'dups', 'uid'),
  String          $ruby             = $facts['ruby']['sitedir'].regsubst('/lib/.*$', '/bin/ruby'),
) {
  # lint:ignore:manifest_whitespace_opening_brace_before
  $user = $users.lest || {[] }.reduce({}) |$memo, $value| {
    $memo + { $value['name'] => $value }
  }
  $group = $groups.lest || {[] }.reduce({}) |$memo, $value| {
    $memo + { $value['name'] => $value }
  }
  # lint:endignore

  $shadow_options = $empty_shadow ? {
    true    => {},
    default => { 'noop' => true },
  }

  unless $group['shadow'] =~ Undef or $group['shadow'].empty {
    $user.each |$key, $value| {
      if $value['gid'] == $group['shadow']['gid'] and ($value['uid'] != 0 or $key == 'root') {
        if $value['uid'] < $uid_min {
          $system = { 'system' => true }
          if $sa_nologin and !($key in $sa_exclude) {
            $shell = $nologin_shell
          } else {
            $shell = $value['shell']
          }
        } else {
          $system = { 'system' => false }
          $shell = $value['shell']
        }

        group { $key:
          ensure => present,
          *      => $shadow_options + $system,
        }

        user { $key:
          ensure     => present,
          uid        => $value['uid'],
          gid        => $key,
          comment    => $value['gecos'],
          home       => $value['dir'],
          managehome => false,
          shell      => $shell,
          *          => $shadow_options,
        }
      }
    }
  }

  if $to_lock =~ Array {
    $passwd_l_options = $lock ? {
      true    => {},
      default => { 'noop' => true },
    }

    $to_lock.each |$u| {
      exec { "/usr/bin/passwd -l ${u}":
        * => $passwd_l_options,
      }

      if defined(Exec["/sbin/userdel -f ${u}"]) {
        Exec["/usr/bin/passwd -l ${u}"] -> Exec["/sbin/userdel -f ${u}"]
      }
    }
  }

  if $to_expire =~ Array {
    $chage_e_options = $expire ? {
      true    => {},
      default => { 'noop' => true },
    }

    $today = Timestamp.new().strftime('%F')
    $to_expire.each |$u| {
      exec { "/usr/bin/chage -E ${today} ${u}":
        * => $chage_e_options,
      }

      if defined(Exec["/sbin/userdel -f ${u}"]) {
        Exec["/usr/bin/chage -E ${today} ${u}"] -> Exec["/sbin/userdel -f ${u}"]
      }
    }
  }

  $user.filter |$value| {
    $value[1]['uid'] == 0 and $value[0] != 'root'
  }.each |$key, $value| {
    $uid_0_options = $remove_uid_0 ? {
      true    => {},
      default => { 'noop' => true },
    }

    exec { "/sbin/userdel -f ${key}":
      * => $uid_0_options,
    }
  }

  $dups_noop = $remove_dups ? {
    true    => {},
    default => { 'noop' => true },
  }

  $remove_duplicates_users_script = [
    '["/etc/passwd", "/etc/shadow"].each { |file|',
    'contents = []; File.open(file, "r") { |fh|',
    'dup = {}; contents = fh.readlines; contents.delete_if { |line|',
    'name = line.split(":").first; ret = dup[name]; dup[name] = true; ret }; };',
    'File.open(file, "w") { |fh| fh.puts contents.join("") } }',
  ]

  $remove_duplicates_uids_script = [
    'user = []; File.open("/etc/passwd", "r") { |fh|',
    'dup = {}; user = fh.readlines; user.delete_if { |line|',
    'uid = line.split(":")[2]; ret = dup[uid]; dup[uid] = true; ret }; };',
    'File.open("/etc/passwd", "w") { |fh|',
    'fh.puts user.join("") }; shadow = []; File.open("/etc/shadow", "r") { |fh|',
    'shadow = fh.readlines; shadow.select! { |line|',
    'name = line.split(":").first; user.any? { |u|',
    '%r{^#{name}:}.match(u) } } };',
    'File.open("/etc/shadow", "w") { |fh|',
    'fh.puts shadow.join("") }',
  ]

  unless $duplicate_users =~ Undef {
    exec { 'Remove duplicate users':
      command => [$ruby, '-e', "'${$remove_duplicates_users_script.join(' ')}'"].join(' '),
      *       => $dups_noop,
    }
  }

  unless $duplicate_uids =~ Undef {
    exec { 'Remove duplicate UIDs':
      command => [$ruby, '-e', "'${$remove_duplicates_uids_script.join(' ')}'"].join(' '),
      *       => $dups_noop,
    }
  }

  $user.filter |$value| {
    $value[1]['passwd'] != 'x'
  }.each |$key, $value| {
    $aug_noop = $force_shadow ? {
      true    => {},
      default => { 'noop' => true },
    }

    augeas { "${key}-password":
      context => "/files/etc/passwd/${key}",
      changes => 'set password x',
      *       => $aug_noop,
    }
  }

  $user.filter |$value| {
    $value[1]['uid'] != 0 and $value[1]['uid'] < $uid_min and $value[1]['shell'] != $nologin_shell and !($value[0] in $sa_exclude)
  }.each |$key, $value| {
    unless defined(User[$key]) {
      $user_params = $value.reduce({}) |$memo, $param| { # lint:ignore:manifest_whitespace_opening_brace_before
        $this_key = $param[0] ? {
          'gecos' => 'comment',
          'dir'   => 'home',
          default => $param[0],
        }
        if $this_key == 'passwd' {
          $memo
        } else {
          $memo + { $this_key => $param[1] }
        }
      }

      $user_noop = $sa_nologin ? {
        true    => {},
        default => { 'noop' => true },
      }

      user { $key:
        * => $user_params + $user_noop + { 'shell' => $nologin_shell },
      }

      unless $to_lock =~ Array and $key in $to_lock {
        exec { "/usr/bin/passwd -l ${key}":
          * => $user_noop,
        }
      }
    }
  }
}
