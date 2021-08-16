# @summary Helper profile class for simp_enterprise_el_* modules
#
# @param kernel_parameters `kernel_parameter` resources to manage
# @param services `service` resources to manage
# @param sysctl_flags `sysctl` resources to manage
# @param files a list of files to manage
# @param ini_settings a list of ini_settings to manage
#
# @example
#   include simp_enterprise_el
class simp_enterprise_el (
  Hash $kernel_parameters,
  Hash $services,
  Hash $sysctl_flags,
  Hash $files,
  Hash $ini_settings,
  Hash $kernel_parameter_defaults,
  Hash $service_defaults,
  Hash $sysctl_flag_defaults,
  Hash $file_defaults,
  Hash $ini_setting_defaults,
  Hash $kernel_parameter_overrides,
  Hash $service_overrides,
  Hash $sysctl_flag_overrides,
  Hash $file_overrides,
  Hash $ini_setting_overrides
) {
  $kernel_parameters.each |$key, $value| {
    simp_enterprise_el::resource::kernel_parameter { $key:
      params => $kernel_parameter_defaults + $value + $kernel_parameter_overrides,
    }
  }

  $services.each |$key, $value| {
    simp_enterprise_el::resource::service { $key:
      params => $service_defaults + $value + $service_overrides,
    }
  }

  $sysctl_flags.each |$key, $value| {
    simp_enterprise_el::resource::sysctl { $key:
      params => $sysctl_flag_defaults + $value + $sysctl_flag_overrides,
    }
  }

  $files.each |$key, $value| {
    simp_enterprise_el::resource::file { $key:
      params => $file_defaults + $value + $file_overrides,
    }
  }

  $ini_settings.each |$key, $value| {
    simp_enterprise_el::resource::ini_setting {$key:
      params => $ini_setting_defaults + $value + $ini_setting_overrides
    }
  }
}
