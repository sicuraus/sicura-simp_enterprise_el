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
  # The original implementation of this class used a `file` resource with the content
  # set to the contents of `$env` minus anything in `$env_exclude`.  As a result, any
  # unmanaged value was removed.
  #
  # Using the `shellvar` resource, we need to explicitly set any excluded value to
  # `ensure => absent`.
  #
  # To iterate over `$env_exclude`, we convert it into a hash where each element is
  # the key and the value is set to `undef`.  That is merged with `$env`.
  ($env_exclude.reduce({}) |$memo, $key| { $memo + { $key => undef } } + $env).each |$k, $v| {
    $ensure = $k in $env_exclude ? {
      true => 'absent',
      default => 'present',
    }

    simp_enterprise_el::resource::shellvars { "${env_file}-${k}":
      params => {
        ensure   => $ensure,
        target   => $env_file,
        variable => $k,
        value    => $v,
      },
    }
  }
}
