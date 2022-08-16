# @summary Remove all keytab files under /etc
#
# @param enforce Enforce removal
# @param ignore Array of keytab files
# @param defaults Hash of default file parameters to perform on keytab files
# @param files List of keytabs files
#
# @example
#   include simp_enterprise_el::keytabs
class simp_enterprise_el::keytabs (
  Boolean                           $enforce,
  Hash                              $defaults = { ensure => 'absent' },
  Optional[Array[Stdlib::Unixpath]] $ignore = [],
  Optional[Array[Stdlib::Unixpath]] $files = $facts['simp_enterprise_el__keytabs'],
) {

  $_defaults = $enforce ? {
    true    => $defaults,
    default => $defaults + { 'noop' => true }
  }

  $_filtered_files = $files ? {
    nil => [],
    default => $files.delete($ignore)
  }

  $_filtered_files.each |$file| {
    simp_enterprise_el::resource::file { $file:
      params => $_defaults,
    }
  }
}
