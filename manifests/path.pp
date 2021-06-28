# @summary PATH validation
#
# @example
#   include simp_enterprise_el::path
class simp_enterprise_el::path {
  file { "/etc/profile.d/${module_name}_path.sh":
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => file("${module_name}/path.sh"),
  }
}
