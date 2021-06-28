# @summary Manage permissions on cron files/directories
#
# @param enforce When `false`, resources are set to `noop` for reporting
#
# @example
#   include simp_enterprise_el::cron
class simp_enterprise_el::cron (
  $enforce = false,
) {
  $noop = $enforce ? {
    true    => {},
    default => { 'noop' => true },
  }

  file { [
    '/etc/cron.hourly',
    '/etc/cron.daily',
    '/etc/cron.weekly',
    '/etc/cron.monthly',
    '/etc/cron.d',
  ]:
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0700',
    *      => $noop,
  }

  file { '/etc/crontab':
    ensure => file,
    owner  => 'root',
    group  => 'root',
    mode   => '0600',
    *      => $noop,
  }
}
