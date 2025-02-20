# @summary Optionally manage or override group resources
#
# @param params Resource attributes
# @param override
#   Override existing resources.  When `undef` or `true`, add any attributes to
#   the existing resource.
# @param ignore When `true`, skip this resource.
#
# @example
#   simp_enterprise_el::resource::group { 'foo':
#     params => {
#       ensure => 'present',
#       gid    => 1001,
#     },
#   }
define simp_enterprise_el::resource::group (
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
    if defined(Group[$title]) {
      if $_override {
        Group <| title == $title |> {
          * => $_params,
        }
        notice("${title}, OVERRIDING Params = ${_params}")
      }
    } else {
      group { $title:
        * => $_params,
      }
    }
  }
}
