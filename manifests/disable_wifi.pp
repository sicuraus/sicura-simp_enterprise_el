# @summary Disable wireless interfaces
#
# @param interfaces Wireless interfaces
# @param enforce Enforce disabling wireless interfaces
#
# @example
#   include simp_enterprise_el::disable_wifi
class simp_enterprise_el::disable_wifi (
  Optional[Hash] $interfaces = $facts['simp_enterprise_el__wifi'],
  Boolean        $enforce    = false,
) {
  $noop = $enforce ? {
    true    => {},
    default => { 'noop' => true },
  }

  # Try globally disabling wireless interfaces with nmcli
  exec { '/usr/bin/nmcli radio all off':
    onlyif => '/bin/bash -c \'[ "$( /usr/bin/nmcli radio wifi )" = enabled ]\'',
    *      => $noop,
  }

  $interfaces.lest || {{} }.each |$key, $value| {
    if $value.dig('radio', 'on') {
      # Disable the wireless radio
      exec { "/bin/sh -c 'echo 0 > ${value['radio']['state_file']}'":
        * => $noop,
      }
    }

    if $value['link_up'] {
      # Set the link down
      exec { "/bin/sh -c 'echo 0x1002 > /sys/class/net/${key}/flags'":
        * => $noop,
      }
    }
  }
}
