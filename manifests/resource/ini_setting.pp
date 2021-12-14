# @summary Optionally manage or override ini_setting resources
#
# @param params Resource attributes
# @param override
#   Override existing resources.  When `undef` or `true`, add any attributes to
#   the existing resource.
# @param ignore When `true`, skip this resource.
#
# @example
#   simp_enterprise_el::resource::ini_setting { 'Coredump_Storage':
#      params => {
#        ensure => present,
#        path              => '/etc/systemd/coredump.conf',
#        section           => 'Coredump',
#        key_val_separator => '=',
#        setting           => 'Storage',
#        value             => 'none'
#      }
#   }
define simp_enterprise_el::resource::ini_setting (
  Hash              $params   = {},
  Optional[Boolean] $override = $params['override'],
  Optional[Boolean] $ignore   = $params['ignore'],
) {
  $_params = $params.filter |$v| { $v[0] != 'override' and $v[0] != 'ignore' }

  if $override == true or $override =~ Undef {
    $_override = true
  } else {
    $_override = false
  }

  unless $ignore {
    if defined(Ini_setting[$title]) {
      if $_override {
        Ini_setting <| title == $title |> {
          * => $_params,
        }
      }
    } else {
      ini_setting { $title:
        * => $_params,
      }
    }
  }
}
