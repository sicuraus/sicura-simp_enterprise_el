# @summary Manage problematic . files in users' home directories
#
# @param remove_rhosts Remove users' .rhosts files
# @param remove_shosts Remove users' .shosts files
# @param remove_netrc Remove users' .netrc files
# @param remove_forward Remove users' .forward files
# @param dotfiles File resources to manage
# @param enforce When `false`, resources are set to `noop` for reporting
#
# @example
#   include simp_enterprise_el::dotfiles
class simp_enterprise_el::dotfiles (
  Boolean        $remove_rhosts  = false,
  Boolean        $remove_shosts  = false,
  Boolean        $remove_netrc   = false,
  Boolean        $remove_forward = false,
  Optional[Hash] $dotfiles       = $facts.dig('simp_enterprise_el__facts', 'dotfiles'),
  Boolean        $enforce        = false,
) {
  $dotfiles.lest || {{} }.each |$key, $value| {
    $absent = { 'ensure' => 'absent' }
    $noop = { 'noop' => 'true' }

    $defaults = $enforce ? {
      true    => {},
      default => $noop,
    }

    $overrides = $key ? {
      /\/.rhosts$/ => $remove_rhosts ? {
        true    => $absent,
        default => $defaults,
      },
      /\/.netrc$/  => $remove_netrc ? {
        true    => $absent,
        default => $defaults,
      },
      /\/.forward$/ => $remove_forward ? {
        true    => $absent,
        default => $defaults,
      },
      /\/.shosts$/ => $remove_shosts ? {
        true    => $absent,
        default => $defaults,
      },
      default => $defaults
    }

    simp_enterprise_el::resource::file { $key:
      params => $value + $overrides,
    }
  }
}
