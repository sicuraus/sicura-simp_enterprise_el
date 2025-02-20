# @summary Optionally manage or override sshd_config resources
#
# @param params Resource attributes
# @param override
#   Override existing resources.  When `undef` or `true`, add any attributes to
#   the existing resource.
# @param ignore When `true`, skip this resource.
#
# @example
#   simp_enterprise_el::resource::sshd_config { 'PubkeyAuthentication':
#      params => {
#        ensure => present,
#        value  => 'yes'
#      }
#   }
define simp_enterprise_el::resource::sshd_config (
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
    if defined(Sshd_config[$title]) {
      if $_override {
        Sshd_config <| title == $title |> {
          * => $_params,
        }
        notice("${title}, OVERRIDING Params = ${_params}")
      }
    } else {
      sshd_config { $title:
        * => $_params,
      }
    }
  }
}
