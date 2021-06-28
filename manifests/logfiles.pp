# @summary Manage permissions on log files
#
# @param enforce Enforce permissions
# @param ignore Array of regular expressions to ignore
# @param mode Permissions for all files (as an octal string)
# @param files List of log files
#
# @example
#   include simp_enterprise_el::logfiles
class simp_enterprise_el::logfiles (
  Boolean                                                $enforce,
  Array                                                  $ignore,
  Pattern[/\A[0-7]{1,4}\z/]                              $mode,
  Optional[Hash[Stdlib::Unixpath, Hash[String, String]]] $files = $facts['simp_enterprise_el__logfiles'],
) {
  $files.lest || { {} }.reduce({}) |$memo, $value| {
    if $ignore.any |$pattern| { $value[0] =~ Regexp.new($pattern) } {
      $memo
    } else {
      $memo + $value
    }
  }.each |$key, $value| {
    if defined(File[$key]) {
      if $enforce {
        File <| title == $key |> {
          mode => $mode,
        }
      }
    } else {
      $noop = $enforce ? {
        true    => {},
        default => { 'noop' => true },
      }

      $newmode = $value['mode'] ? {
        /^0[0-7]{0,3}$/ => inline_template("<%= '0' + ('${value['mode']}'.to_i(8) & '${mode}'.to_i(8)).to_s(8) %>"),
        default         => $mode,
      }

      file { $key:
        ensure => file,
        mode   => $newmode,
        *      => $noop,
      }
    }
  }
}
