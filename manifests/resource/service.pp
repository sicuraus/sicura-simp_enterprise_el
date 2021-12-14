# @summary Optionally manage or override service resources
#
# @param params Resource attributes
# @param override
#   Override existing resources.  When `undef` or `true`, add any attributes to
#   the existing resource.
# @param ignore When `true`, skip this resource.
#
# @example
#   simp_enterprise_el::resource::service { 'rsyncd':
#     params => {
#       'ensure' => 'stopped',
#       'enable' => false,
#     },
#   }
define simp_enterprise_el::resource::service (
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
    # Workaround for https://tickets.puppetlabs.com/browse/PUP-10974
    # Rather than set `enable` to `mask`, we will set it to `false`
    # and run `systemctl mask` in an `exec` resource.
    case $_params['enable'] {
      'mask': {
        $mask = true
        $_value = $_params + { 'enable' => false }
      }
      default: {
        $mask = false
        $_value = $_params
      }
    }

    if defined(Service[$title]) {
      if $_override {
        Service <| title == $title |> {
          * => $_value,
        }

        $managed = true
      } else {
        $managed = false
      }
    } else {
      service { $title:
        * => $_value,
      }

      $managed = true
    }

    # Part 2 of workaround for https://tickets.puppetlabs.com/browse/PUP-10974
    if $mask and $managed {
      exec { "systemctl mask ${title}":
        path    => '/bin:/usr/bin',
        unless  => "[ \"\$( systemctl is-enabled ${title} 2>/dev/null )\" = masked ]",
        require => Service[$title],
      }
    }
  }
}
