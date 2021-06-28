# @summary Manage users' home directories
#
# @param uid_min Don't manage home directory if the owner UID is below this number
# @param homes Home directories to manage
# @param defaults Defaults for all home directories
# @param enforce When `false`, resources are set to `noop` for reporting
#
# @example
#   include simp_enterprise_el::homes
class simp_enterprise_el::homes (
  Integer[0]     $uid_min  = Integer($facts['uid_min'].lest || { 1000 }),
  Optional[Hash] $homes    = $facts.dig('simp_enterprise_el__facts', 'homes'),
  Hash           $defaults = { 'mode' => '0700' },
  Boolean        $enforce  = false,
) {
  $_defaults = $enforce ? {
    true    => $defaults,
    default => $defaults + { 'noop' => true }
  }

  $homes.lest || { {} }.each |$key, $value| {
    unless $value['owner'] < $uid_min {
      file { $key:
        * => $_defaults + $value,
      }
    }
  }
}
