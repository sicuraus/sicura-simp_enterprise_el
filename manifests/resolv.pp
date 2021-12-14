# @summary resolv.conf validation
# 
# @param min_num_nameservers If resolv.conf is configured with less nameservers than this parameter specifies, notify the user
# @param nameservers System nameservers
#
# @example
#   include simp_enterprise_el::resolv
class simp_enterprise_el::resolv(
  Integer[0,3]            $min_num_nameservers = 0,
  Optional[Array[String]] $nameservers         = $facts.dig('simp_enterprise_el__resolv', 'nameservers'),
) {
  if $nameservers.lest || { [] }.unique.length < $min_num_nameservers {
    notify { "This host has less than ${min_num_nameservers} nameservers configured in resolv.conf":}
  }
}
