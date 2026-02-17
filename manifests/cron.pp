# @summary Manage permissions on cron files/directories
#
# @param enforce When `false`, resources are set to `noop` for reporting
# @param crontab Path to crontab file
# @param cron_dirs Paths to cron directories
#
# @example
#   include simp_enterprise_el::cron
class simp_enterprise_el::cron (
  Boolean          $enforce   = false,
  Stdlib::Unixpath $crontab   = '/etc/crontab',
  Array            $cron_dirs = [
    '/etc/cron.hourly',
    '/etc/cron.daily',
    '/etc/cron.weekly',
    '/etc/cron.monthly',
    '/etc/cron.yearly',
    '/etc/cron.d',
  ],
) {
  $noop = $enforce ? {
    true    => {},
    default => { 'noop' => true },
  }

  simp_enterprise_el::resource::file { $cron_dirs:
    params => {
      'ensure' => 'directory',
      'owner'  => 'root',
      'group'  => 'root',
      'mode'   => '0700',
    } + $noop,
  }

  simp_enterprise_el::resource::file { $crontab:
    params => {
      'ensure' => 'file',
      'owner'  => 'root',
      'group'  => 'root',
      'mode'   => '0600',
    } + $noop,
  }
}
