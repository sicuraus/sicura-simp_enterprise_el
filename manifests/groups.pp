# @summary Check for problems with local groups
#
# @param users List of local users
# @param groups List of local groups
# @param empty_shadow Enforce shadow group with empty member list
# @param missing_groups Missing group resource list
# @param add_missing Enforce missing group resources
# @param duplicate_groups List of duplicated groups
# @param duplicate_gids List of duplicated gids
# @param remove_dups Enforce removing duplicate groups or GIDs
# @param ruby Path to ruby executable
#
# @example
#   include simp_enterprise_el::groups
class simp_enterprise_el::groups (
  Optional[Array] $users            = $facts.dig('simp_enterprise_el__facts', 'users'),
  Optional[Array] $groups           = $facts.dig('simp_enterprise_el__facts', 'groups'),
  Boolean         $empty_shadow     = false,
  Optional[Hash]  $missing_groups   = $facts.dig('simp_enterprise_el__facts', 'missing_groups'),
  Boolean         $add_missing      = false,
  Optional[Hash]  $duplicate_groups = $facts.dig('simp_enterprise_el__facts', 'dups', 'groupname'),
  Optional[Hash]  $duplicate_gids   = $facts.dig('simp_enterprise_el__facts', 'dups', 'gid'),
  Boolean         $remove_dups      = false,
  String          $ruby             = $facts['ruby']['sitedir'].regsubst('/lib/.*$', '/bin/ruby'),
) {
  $user = $users.lest || { [] }.reduce({}) |$memo, $value| {
    $memo + { $value['name'] => $value }
  }
  $group = $groups.lest || { [] }.reduce({}) |$memo, $value| {
    $memo + { $value['name'] => $value }
  }

  unless $group['shadow'] =~ Undef or $group['shadow']['mem'].empty {
    $noop = $empty_shadow ? {
      true    => {},
      default => { 'noop' => true },
    }

    exec { '/usr/bin/gpasswd -M "" shadow':
      * => $noop,
    }
  }

  $missing_groups.lest || { {} }.each |$key, $value| {
    $noop = $add_missing ? {
      true    => {},
      default => { 'noop' => true },
    }

    # Missing groups will be added as username_xxxx, where 'username' is the
    # first user with the missing group as a primary group, and where 'xxxx' is
    # a random string seeded with the username.
    # Since group names have a maximum length of 32 characters, the username is
    # truncated to 27 characters.
    group { "${key[0, 27]}_${fqdn_rand_string(4, '', $key).downcase}":
      * => $value + $noop,
    }
  }

  $dups_noop = $remove_dups ? {
    true => {},
    default => { 'noop' => true },
  }

  $remove_duplicates_groups_script = [
    '["/etc/group", "/etc/gshadow"].each { |file|',
    'contents = []; File.open(file, "r") { |fh|',
    'dup = {}; contents = fh.readlines; contents.delete_if { |line|',
    'name = line.split(":").first; ret = dup[name]; dup[name] = true; ret }; };',
    'File.open(file, "w") { |fh| fh.puts contents.join("") } }',
  ]

  $remove_duplicates_gids_script = [
    'group = []; File.open("/etc/group", "r") { |fh|',
    'dup = {}; group = fh.readlines; group.delete_if { |line|',
    'gid = line.split(":")[2]; ret = dup[gid]; dup[gid] = true; ret }; };',
    'File.open("/etc/group", "w") { |fh|',
    'fh.puts group.join("") }; gshadow = []; File.open("/etc/gshadow", "r") { |fh|',
    'gshadow = fh.readlines; gshadow.select! { |line|',
    'name = line.split(":").first; group.any? { |g|',
    '%r{^#{name}:}.match(g) } } };',
    'File.open("/etc/gshadow", "w") { |fh|',
    'fh.puts gshadow.join("") }',
  ]

  unless $duplicate_groups =~ Undef {
    exec { 'Remove duplicate groups':
      command => [$ruby, '-e', "'${$remove_duplicates_groups_script.join(' ')}'"].join(' '),
      *       => $dups_noop,
    }
  }

  unless $duplicate_gids =~ Undef {
    exec { 'Remove duplicate GIDs':
      command => [$ruby, '-e', "'${$remove_duplicates_gids_script.join(' ')}'"].join(' '),
      *       => $dups_noop,
    }
  }
}
