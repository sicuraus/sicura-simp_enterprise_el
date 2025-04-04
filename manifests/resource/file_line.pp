########################################################################
# WARNING: Do not use this feature unless there is no other option
#          For example, if you need to edit a line in a config file
#          ensure there is not currently a module to modify that config
########################################################################
#
# @summary Optionally manage or override file_line resources
#
# @param params Resource attributes
# @param override
#   Override existing resources.  When `undef` or `true`, add any attributes to
#   the existing resource.
# @param ignore When `true`, skip this resource.
#
# @example
#   simp_enterprise_el::resource::file_line { 'add_line_to_unamanaged_file':
#     ensure => present,
#     path   => '/tmp/testfile',
#     line   => 'newline1 = foo',
#     match  => '^newline1\ =',
#   }
define simp_enterprise_el::resource::file_line (
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
    if defined(File_line[$title]) {
      if $_override {
        File_line <| title == $title |> {
          * => $_params,
        }
      }
    } else {
      file_line { $title:
        * => $_params,
      }
    }
  }
}
