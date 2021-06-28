# @summary Helper profile class for simp_enterprise_el_* modules
#
# @param kernel_parameters kernel_parameter resources to manage
# @param services Service resources to manage
#
# @example
#   include simp_enterprise_el
class simp_enterprise_el (
  Hash $kernel_parameters,
  Hash $services,
  Hash $sysctl_flags,
) {
  $kernel_parameters.each |$key, $value| {
    kernel_parameter { $key:
      * => $value,
    }
  }

  $services.each |$key, $value| {
    if defined(Service[$key]) {
      Service <| title == $key |> {
        * => $value,
      }
    } else {
      service { $key:
        * => $value,
      }
    }
  }

  $sysctl_flags.each |$key, $value| {
    sysctl { $key:
      * => $value,
    }
  }
}
