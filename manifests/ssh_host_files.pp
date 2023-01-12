# @summary Manage ssh host key files
#
# @param ssh_host_keys Hash of system ssh private key files
# @param ssh_host_key_mode the mode for all /etc/ssh/ssh_host_*_key files
# @param ssh_host_key_owner the owner for all /etc/ssh/ssh_host_*_key files
# @param ssh_host_key_group the group for all /etc/ssh/ssh_host_*_key files
# @param ssh_host_pub_keys Hash of system ssh pub key files
# @param ssh_host_pub_key_mode the mode for all /etc/ssh/ssh_host_*_key.pub files
# @param ssh_host_pub_key_owner the owner for all /etc/ssh/ssh_host_*_key.pub files
# @param ssh_host_pub_key_group the group for all /etc/ssh/ssh_host_*_key.pub files
# 
#
# @example
#   include simp_enterprise_el::ssh_host_files
class simp_enterprise_el::ssh_host_files (
  Optional[Array[Stdlib::Unixpath]] $ssh_host_keys          = $facts.dig('simp_enterprise_el__ssh_host_files', 'ssh_host_key_files'),
  Stdlib::Filemode                  $ssh_host_key_mode      = 'u-x,g-wx,o-rwx',
  String                            $ssh_host_key_owner     = 'root',
  String                            $ssh_host_key_group     = 'root',
  Optional[Array[Stdlib::Unixpath]] $ssh_host_pub_keys      = $facts.dig('simp_enterprise_el__ssh_host_files', 'ssh_host_pub_files'),
  Stdlib::Filemode                  $ssh_host_pub_key_mode  = 'u-x,go-wx',
  String                            $ssh_host_pub_key_owner = 'root',
  String                            $ssh_host_pub_key_group = 'root',
) {
  $ssh_host_keys.lest || {{} }.each | $host_key | {
    simp_enterprise_el::resource::file { $host_key:
      params => {
        ensure => 'file',
        mode   => $ssh_host_key_mode,
        owner  => $ssh_host_key_owner,
        group  => $ssh_host_key_group,
      },
    }
  }
  $ssh_host_pub_keys.lest || {{} }.each | $host_key | {
    simp_enterprise_el::resource::file { $host_key:
      params => {
        ensure => 'file',
        mode   => $ssh_host_pub_key_mode,
        owner  => $ssh_host_pub_key_owner,
        group  => $ssh_host_pub_key_group,
      },
    }
  }
}
