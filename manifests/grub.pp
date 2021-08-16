# @summary Manage bootloader configuration file permissions
#
# @param files Files to manage
# @param enforce Enforce file permissions
# @param defaults File permissions
#
# @example
#   include simp_enterprise_el::grub
class simp_enterprise_el::grub (
  Hash                                   $defaults,
  Boolean                                $enforce,
  Optional[Hash[Stdlib::Unixpath, Hash]] $files = $facts['simp_enterprise_el__grub'],
) {
  $noop = $enforce ? {
    true    => {},
    default => { 'noop' => true },
  }

  $files.lest || { {} }.each |$key, $value| {
    simp_enterprise_el::resource::file { $key:
      params => $defaults + $value + $noop,
    }
  }
}
