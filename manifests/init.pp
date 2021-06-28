# @summary Helper profile class for simp_enterprise_el_* modules
#
# @param kernel_parameters `kernel_parameter` resources to manage
# @param services `service` resources to manage
# @param sysctl_flags `sysctl` resources to manage
# @param files a list of files to manage
#
# @example
#   include simp_enterprise_el
class simp_enterprise_el (
  Hash $kernel_parameters,
  Hash $services,
  Hash $sysctl_flags,
  Hash $files,
) {
  $kernel_parameters.each |$key, $value| {
    kernel_parameter { $key:
      * => $value,
    }
  }

  $services.each |$key, $value| {
    # Workaround for https://tickets.puppetlabs.com/browse/PUP-10974
    # Rather than set `enable` to `mask`, we will set it to `false`
    # and run `systemctl mask` in an `exec` resource.
    case $value['enable'] {
      'mask': {
        $mask = true
        $_value = $value + { 'enable' => false }
      }
      default: {
        $mask = false
        $_value = $value
      }
    }

    if defined(Service[$key]) {
      Service <| title == $key |> {
        * => $_value,
      }
    } else {
      service { $key:
        * => $_value,
      }
    }

    # Part 2 of workaround for https://tickets.puppetlabs.com/browse/PUP-10974
    if $mask {
      exec { "systemctl mask ${key}":
        path    => '/bin:/usr/bin',
        unless  => "[ \"\$( systemctl is-enabled ${key} 2>/dev/null )\" = masked ]",
        require => Service[$key],
      }
    }
  }

  $sysctl_flags.each |$key, $value| {
    sysctl { $key:
      * => $value,
    }
  }

  $files.each |$key, $value| {
    if defined(File[$key]) {
      File <| title == $key |> {
        * => $value,
      }
    } else {
      file { $key:
        * => $value,
      }
    }
  }
}
