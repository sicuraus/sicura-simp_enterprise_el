# @summary Manage sshd environment file
#
# @param env_file Path to environment file
# @param env Environment to include in environment file
# @param env_exclude Environment variables to exclude from environment file
#
# @example
#   include simp_enterprise_el::sshd
class simp_enterprise_el::sshd (
  Stdlib::Unixpath        $env_file,
  Hash[String[1], String] $env,
  Array[String[1]]        $env_exclude,
) {
  file { $env_file:
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0640',
    content => (['# Managed by Puppet'] + $env.map |$k, $v| { unless $k in $env_exclude { "${k}='${v}'" } }).join("\n"),
  }
}
