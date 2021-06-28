# @summary Manage dconf settings
#
# @param dconf_settings a hash that will provide the necessary parameters to create a dconf_settings object
# @example
#   simp_enterprise_el::dconf::dconf_settings:
#     00-defaults:
#       settings_hash:
#         org/gnome/login-screen:
#           enable-smartcard-authentication:
#             value: true
#             lock: true
# @example
#   include simp_enterprise_el::dconf
class simp_enterprise_el::dconf (
  Hash $dconf_settings = {}
) {
  $dconf_settings.each |$key, $value| {
    dconf::settings { $key:
      * => $value,
    }
  }
}
