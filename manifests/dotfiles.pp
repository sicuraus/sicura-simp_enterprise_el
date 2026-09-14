# @summary Manage problematic . files in users' home directories
#
# The `simp_enterprise_el__facts` fact reports every dot file at the top level
# of each interactive user's home directory along with its current owner,
# group and mode.  Which of those files are out of policy, and what to do
# about them, is decided here from the class parameters, so that each
# benchmark rule turns on only the behaviour it asks for.
#
# With the defaults, a dot file is managed only when its mode has bits set in
# `mask` (or the matching entry in `masks`), and only its owner and mode are
# set.  A file listed by one of the `remove_*` parameters is always managed so
# that it can be removed.
#
# @param remove_rhosts Remove users' .rhosts files
# @param remove_shosts Remove users' .shosts files
# @param remove_netrc Remove users' .netrc files
# @param remove_forward Remove users' .forward files
# @param mask Permission bits to strip from dot files
# @param directory_mask Permission bits to strip from dot directories
# @param masks Per-file overrides of `mask`, keyed by file name
# @param manage_ownership
#   When `true`, also manage a dot file whose owner is not the user or whose
#   group is not the user's primary group, and set both on every managed file.
#   When `false`, only the owner is set, and only on files whose mode is out
#   of policy.
# @param dotfiles Dot files reported by the fact
# @param enforce When `false`, resources are set to `noop` for reporting
#
# @example
#   include simp_enterprise_el::dotfiles
#
# @example CIS "local interactive user dot files access"
#   class { 'simp_enterprise_el::dotfiles':
#     mask             => '0133',
#     masks            => { '.netrc' => '0177', '.bash_history' => '0177' },
#     manage_ownership => true,
#     enforce          => true,
#   }
class simp_enterprise_el::dotfiles (
  Boolean                                   $remove_rhosts    = false,
  Boolean                                   $remove_shosts    = false,
  Boolean                                   $remove_netrc     = false,
  Boolean                                   $remove_forward   = false,
  Simp_enterprise_el::Mask                  $mask             = '0022',
  Simp_enterprise_el::Mask                  $directory_mask   = '0022',
  Hash[String[1], Simp_enterprise_el::Mask] $masks            = { '.netrc' => '0077' },
  Boolean                                   $manage_ownership = false,
  Optional[Hash]                            $dotfiles         = $facts.dig('simp_enterprise_el__facts', 'dotfiles'),
  Boolean                                   $enforce          = false,
) {
  # Files with a remove_* switch are always managed so that the switch has
  # something to act on, and show up in reports whether or not it is set.
  $removable = ['.rhosts', '.shosts', '.netrc', '.forward']

  $absent = { 'ensure' => 'absent' }
  $noop = { 'noop' => 'true' }

  $defaults = $enforce ? {
    true    => {},
    default => $noop,
  }

  $dotfiles.lest || { {} }.each |$key, $value| {
    $file = $key.regsubst('^.*/', '')
    $current = $value['current'].lest || { {} }

    $file_mask = $value['ensure'] ? {
      'directory' => $directory_mask,
      default     => $masks[$file].lest || { $mask },
    }

    $target_mode = $current['mode'] ? {
      Undef   => undef,
      default => simp_enterprise_el::apply_mask($current['mode'], $file_mask),
    }

    $misowned = $manage_ownership and (
      $current['owner'] != $value['owner'] or $current['group'] != $value['group']
    )

    if $file in $removable or $target_mode != $current['mode'] or $misowned {
      $drop = $manage_ownership ? {
        true    => ['current'],
        default => ['current', 'group'],
      }

      $mode = $target_mode ? {
        Undef   => {},
        default => { 'mode' => $target_mode },
      }

      $overrides = $file ? {
        '.rhosts'  => $remove_rhosts ? {
          true    => $absent,
          default => $defaults,
        },
        '.netrc'   => $remove_netrc ? {
          true    => $absent,
          default => $defaults,
        },
        '.forward' => $remove_forward ? {
          true    => $absent,
          default => $defaults,
        },
        '.shosts'  => $remove_shosts ? {
          true    => $absent,
          default => $defaults,
        },
        default    => $defaults
      }

      # simp_enterprise_el::initialization_files manages the shell
      # initialization files from its own fact entry; whichever class is
      # evaluated first owns the resource.
      unless defined(Simp_enterprise_el::Resource::File[$key]) {
        simp_enterprise_el::resource::file { $key:
          params => ($value - $drop) + $mode + $overrides,
        }
      }
    }
  }
}
