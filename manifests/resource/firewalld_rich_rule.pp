# @summary Optionally manage or override firewalld_rich_rules
#
# @param params Resource attributes
# @param override
#   Override existing resources.  When `undef` or `true`, add any attributes to
#   the existing resource.
# @param ignore When `true`, skip this resource.
# @param default_zone Zone to add to resources if not otherwise defined
#
# @example
#   simp_enterprise_el::resource::firewalld_rich_rule { 'accept_port_22':
#       ensure  => present,
#       source  => '192.168.1.2/32',
#       service => 'ssh',
#       action  => 'accept',
#   }
define simp_enterprise_el::resource::firewalld_rich_rule (
  Hash              $params       = {},
  Optional[Boolean] $override     = $params['override'],
  Optional[Boolean] $ignore       = $params['ignore'],
  String[1]         $default_zone = simplib::lookup('simp_firewalld::default_zone', { 'default_value' => '99_simp' }),
) {
  $_params = $params.filter |$v| { $v[0] != 'override' and $v[0] != 'ignore' }

  if $override == true or $override =~ Undef {
    $_override = true
  } else {
    $_override = false
  }

  unless $ignore {
    include simp_firewalld

    if defined(Firewalld_rich_rule[$title]) {
      if $_override {
        if Firewalld_rich_rule[$title]['zone'] =~ Undef and $_params['zone'] =~ Undef {
          $_default_zone = { 'zone' => $default_zone }
        } else {
          $_default_zone = {}
        }

        Firewalld_rich_rule <| title == $title |> {
          * => $_params + $_default_zone,
        }
      }
    } else {
      if $_params['zone'] =~ Undef {
        $_default_zone = { 'zone' => $default_zone }
      } else {
        $_default_zone = {}
      }

      firewalld_rich_rule { $title:
        * => $_params + $_default_zone,
      }
    }
  }
}
