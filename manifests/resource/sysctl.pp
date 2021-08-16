# @summary Optionally manage or override sysctl resources
#
# @param params Resource attributes
# @param override
#   Override existing resources.  When `undef` or `true`, add any attributes to
#   the existing resource.
# @param ignore When `true`, skip this resource.
#
# @example
#   simp_enterprise_el::resource::sysctl { 'namevar': }
define simp_enterprise_el::resource::sysctl (
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
    if defined(Sysctl[$title]) {
      if $_override {
        Sysctl <| title == $title |> {
          * => $_params,
        }
      }
    } else {
      sysctl { $title:
        * => $_params,
      }
    }
  }
}
