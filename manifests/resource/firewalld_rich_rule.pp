# @summary Optionally manage or override firewalld_rich_rules
#
# @param params Resource attributes
# @param override
#   Override existing resources.  When `undef` or `true`, add any attributes to
#   the existing resource.
# @param ignore When `true`, skip this resource.
#
# @example
#   simp_enterprise_el::resource::firewalld_rich_rule { 'accept_port_22':
#       ensure => present,
#       source => '192.168.1.2/32',
#       service => 'ssh',
#       action => 'accept',
#   }
define simp_enterprise_el::resource::firewalld_rich_rule (
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
    if defined(Firewalld_rich_rule[$title]) {
      if $_override {
        Firewalld_rich_rule <| title == $title |> {
          *    => $_params,
          zone => $simp_firewalld::default_zone,
        }
      }
    } else {
      firewalld_rich_rule { $title:
        *    => $_params,
        zone => $simp_firewalld::default_zone,
      }
    }
  }
}
