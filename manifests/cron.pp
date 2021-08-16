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

  simp_enterprise_el::resource::file { [
    '/etc/cron.hourly',
    '/etc/cron.daily',
    '/etc/cron.weekly',
    '/etc/cron.monthly',
    '/etc/cron.d',
  ]:
    params => {
      'ensure' => 'directory',
      'owner'  => 'root',
      'group'  => 'root',
      'mode'   => '0700',
    } + $noop,
  }

  simp_enterprise_el::resource::file { '/etc/crontab':
    params => {
      'ensure' => 'file',
      'owner'  => 'root',
      'group'  => 'root',
      'mode'   => '0600',
    } + $noop,
  }
}
