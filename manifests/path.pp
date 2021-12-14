# @summary PATH validation
#
# @param log_facility Log facility to use for PATH validation warnings
# @param warn_to_stderr Also send warnings to STDERR
#
# @example
#   include simp_enterprise_el::path
class simp_enterprise_el::path (
  Simplib::Syslog::LowerPriority $log_facility,
  Boolean                        $warn_to_stderr,
) {
  file { "/etc/profile.d/${module_name}_path.sh":
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => epp("${module_name}/path.sh.epp", {
      'warn_to_stderr' => $warn_to_stderr,
      'log_facility'   => $log_facility,
    }),
  }
}
