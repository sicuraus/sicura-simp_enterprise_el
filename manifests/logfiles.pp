# @summary Manage permissions on log files
#
# @param enforce Enforce permissions
# @param ignore Array of regular expressions to ignore
# @param mode Permissions for all files
# @param files List of log files
#
# @example
#   include simp_enterprise_el::logfiles
class simp_enterprise_el::logfiles (
  Boolean                           $enforce,
  Array                             $ignore,
  Stdlib::Filemode                  $mode,
  Optional[Array[Stdlib::Unixpath]] $files = $facts['simp_enterprise_el__logfiles'],
) {
  $files.lest || { [] }.reduce([]) |$memo, $value| {
    if $ignore.any |$pattern| { $value =~ Regexp.new($pattern) } {
      $memo
    } else {
      $memo + [$value]
    }
  }.each |$file| {
    $noop = $enforce ? {
      true    => {},
      default => { 'noop' => true },
    }

    file { $file:
      ensure => file,
      mode   => $mode,
      *      => $noop,
    }
  }
}
