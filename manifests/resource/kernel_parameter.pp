# @summary Optionally manage or override kernel_parameter resources
#
# @param params Resource attributes
# @param override
#   Override existing resources.  When `undef` or `true`, add any attributes to
#   the existing resource.
# @param ignore When `true`, skip this resource.
#
# @example
#   simp_enterprise_el::resource::kernel_parameter { 'namevar': }
define simp_enterprise_el::resource::kernel_parameter (
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
    if defined(Kernel_parameter[$title]) {
      if $_override {
        Kernel_parameter <| title == $title |> {
          * => $_params,
        }
      }
    } else {
      kernel_parameter { $title:
        * => $_params,
      }
    }
  }
}
