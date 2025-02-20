# @summary Optionally manage or override package resources
#
# @param params Resource attributes
# @param override
#   Override existing resources.  When `undef` or `true`, add any attributes to
#   the existing resource.
# @param ignore When `true`, skip this resource.
#
# @example
#   simp_enterprise_el::resource::package { 'telnet':
#     params {
#       'ensure' => 'absent',
#     },
#   }
define simp_enterprise_el::resource::package (
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
    if defined(Package[$title]) {
      if $_override {
        Package <| title == $title |> {
          * => $_params,
        }
        notice("${title}, OVERRIDING Params = ${_params}")
      }
    } else {
      package { $title:
        * => $_params,
      }
    }
  }
}
