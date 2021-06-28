# @param sa_exclude List of system accounts allowed to have an login shell
#
# @example
#   include simp_enterprise_el::pam
class simp_enterprise_el::pam (
  Optional[Boolean] $system_auth_nullok   = $facts.dig('simp_enterprise_el__pam', 'system-auth_nullok'),
  Optional[Boolean] $password_auth_nullok = $facts.dig('simp_enterprise_el__pam', 'password-auth_nullok'),
) {
  if $system_auth_nullok {
    notify{'"nullok" was found within /etc/pam.d/system-auth':}
  }

  if $password_auth_nullok {
    notify{'"nullok" was found within /etc/pam.d/password-auth':}
  }
}
