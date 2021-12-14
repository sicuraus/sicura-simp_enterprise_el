# @summary Optionally manage or override file resources
#
# @param params Resource attributes
# @param override
#   Override existing resources.  When `undef` or `true`, add any attributes to
#   the existing resource.
# @param ignore When `true`, skip this resource.
#
# @example
#   simp_enterprise_el::resource::file { '/etc/crontab':
#     params => {
#       'ensure' => 'file',
#       'owner'  => 'root',
#       'group'  => 'root',
#       'mode'   => '0600',
#     },
#   }
define simp_enterprise_el::resource::file (
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
    if defined(File[$title]) {
      if $_override {
        File <| title == $title |> {
          * => $_params,
        }
      }
    } else {
      file { $title:
        * => $_params,
      }
    }
  }
}
