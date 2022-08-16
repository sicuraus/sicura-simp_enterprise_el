# @summary Helper profile class for simp_enterprise_el_* modules
#
# @param files `file` resources to manage.  See [the simp_enterprise_el::resource::file defined type](#simp_enterprise_elresourcefile).
# @param file_defaults Default attributes for managed `file` resources
# @param file_overrides Attributes to override for all managed `file` resources
#
# @param file_lines `file_line` resources to manage.  See [the simp_enterprise_el::resource::file_line defined type](#simp_enterprise_elresourcefile_line).
# @param file_line_defaults Default attributes for managed `file_line` resources
# @param file_line_overrides Attributes to override for all managed `file_line` resources
#
# @param ini_settings `ini_setting` resources to manage.  See [the simp_enterprise_el::resource::ini_setting defined type](#simp_enterprise_elresourceini_setting).
# @param ini_setting_defaults Default attributes for managed `ini_setting` resources
# @param ini_setting_overrides Attributes to override for all managed `ini_setting` resources
#
# @param ini_subsettings `ini_subsetting` resources to manage.  See [the simp_enterprise_el::resource::ini_subsetting defined type](#simp_enterprise_elresourceini_subsetting).
# @param ini_subsetting_defaults Default attributes for managed `ini_subsetting` resources
# @param ini_subsetting_overrides Attributes to override for all managed `ini_subsetting` resources
#
# @param kernel_parameters `kernel_parameter` resources to manage.  See [the simp_enterprise_el::resource::kernel_parameter defined type](#simp_enterprise_elresourcekernel_parameter).
# @param kernel_parameter_defaults Default attributes for managed `kernel_parameter` resources
# @param kernel_parameter_overrides Attributes to override for all managed `kernel_parameter` resources
#
# @param packages `package` resources to manage.  See [the simp_enterprise_el::resource::package defined type](#simp_enterprise_elresourcepackage).
# @param package_defaults Default attributes for managed `package` resources
# @param package_overrides Attributes to override for all managed `package` resources
#
# @param services `service` resources to manage.  See [the simp_enterprise_el::resource::service defined type](#simp_enterprise_elresourceservice).
# @param service_defaults Default attributes for managed `service` resources
# @param service_overrides Attributes to override for all managed `service` resources
#
# @param shellvars `shellvar` resources to manage.  See [the simp_enterprise_el::resource::shellvars defined type](#simp_enterprise_elresourceshellvars).
# @param shellvars_defaults Default attributes for managed `shellvar` resources
# @param shellvars_overrides Attributes to override for all managed `shellvar` resources
#
# @param ssh_configs `ssh_config` resources to manage.  See [the simp_enterprise_el::resource::ssh_config defined type](#simp_enterprise_elresourcessh_config).
# @param ssh_config_defaults Default attributes for managed `ssh_config` resources
# @param ssh_config_overrides Attributes to override for all managed `ssh_config` resources
#
# @param sysctl_flags `sysctl` resources to manage.  See [the simp_enterprise_el::resource::sysctl defined type](#simp_enterprise_elresourcesysctl).
# @param sysctl_flag_defaults Default attributes for managed `sysctl` resources
# @param sysctl_flag_overrides Attributes to override for all managed `sysctl` resources
#
# @example
#   include simp_enterprise_el
class simp_enterprise_el (
  Hash $files,
  Hash $file_defaults,
  Hash $file_overrides,
  Hash $file_lines,
  Hash $file_line_defaults,
  Hash $file_line_overrides,
  Hash $ini_settings,
  Hash $ini_setting_defaults,
  Hash $ini_setting_overrides,
  Hash $ini_subsettings,
  Hash $ini_subsetting_defaults,
  Hash $ini_subsetting_overrides,
  Hash $kernel_parameters,
  Hash $kernel_parameter_defaults,
  Hash $kernel_parameter_overrides,
  Hash $packages,
  Hash $package_defaults,
  Hash $package_overrides,
  Hash $services,
  Hash $service_defaults,
  Hash $service_overrides,
  Hash $shellvars,
  Hash $shellvars_defaults,
  Hash $shellvars_overrides,
  Hash $ssh_configs,
  Hash $ssh_config_defaults,
  Hash $ssh_config_overrides,
  Hash $sysctl_flags,
  Hash $sysctl_flag_defaults,
  Hash $sysctl_flag_overrides,
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
    simp_enterprise_el::resource::ini_setting { $key:
      params => $ini_setting_defaults + $value + $ini_setting_overrides,
    }
  }

  $ini_subsettings.each |$key, $value| {
    simp_enterprise_el::resource::ini_subsetting { $key:
      params => $ini_subsetting_defaults + $value + $ini_subsetting_overrides,
    }
  }

  $packages.each |$key, $value| {
    simp_enterprise_el::resource::package { $key:
      params => $package_defaults + $value + $package_overrides,
    }
  }

  $file_lines.each |$key, $value| {
    simp_enterprise_el::resource::file_line { $key:
      params => $file_line_defaults + $value + $file_line_overrides,
    }
  }

  $shellvars.each |$key, $value| {
    simp_enterprise_el::resource::shellvars { $key:
      params => $shellvars_defaults + $value + $shellvars_overrides,
    }
  }

  $ssh_configs.each |$key, $value| {
    simp_enterprise_el::resource::ssh_config { $key:
      params => $ssh_config_defaults + $value + $ssh_config_overrides,
    }
  }
}
