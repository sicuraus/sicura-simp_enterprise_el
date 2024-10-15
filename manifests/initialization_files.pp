# @summary Manage problematic . files in users' home directories
#
# @param initialization_files File resources to manage
# @param enforce When `false`, resources are set to `noop` for reporting
#
# @example
#   include simp_enterprise_el::dotfiles
class simp_enterprise_el::initialization_files (
  Optional[Hash] $initialization_files       = $facts.dig('simp_enterprise_el__facts', 'initialization_files'),
  Boolean        $enforce        = false,
) {
  $initialization_files.lest || {{} }.each |$key, $value| {
    $noop = { 'noop' => 'true' }

    $defaults = $enforce ? {
      true    => {},
      default => $noop,
    }

    simp_enterprise_el::resource::file { $key:
      params => $value + $defaults,
    }
  }
}
