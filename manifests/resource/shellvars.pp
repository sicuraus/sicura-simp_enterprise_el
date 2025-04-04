# @summary Optionally manage or override shellvar resources
#
# @param params Resource attributes
# @param override
#   Override existing resources.  When `undef` or `true`, add any attributes to
#   the existing resource.
# @param ignore When `true`, skip this resource.
#
# @example
#   simp_enterprise_el::resource::shellvar { 'GRUB_CMDLINE_LINUX':
#      params => {
#        ensure       => present,
#        target       => "/etc/default/grub",
#        value        => ["quiet", "cgroup_enable=memory"],
#        array_append => true,
#      }
#   }
define simp_enterprise_el::resource::shellvars (
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
    if defined(Shellvar[$title]) {
      if $_override {
        Shellvar <| title == $title |> {
          * => $_params,
        }
      }
    } else {
      shellvar { $title:
        * => $_params,
      }
    }
  }
}
