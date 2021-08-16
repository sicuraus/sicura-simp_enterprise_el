# @summary PATH validation
#
# @example
#   include simp_enterprise_el::path
class simp_enterprise_el::path (
  Boolean                        $warn_to_stderr,
  Simplib::Syslog::LowerPriority $log_facility,
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
