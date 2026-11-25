# @summary Manage bootloader configuration file permissions
#
# @param files Files to manage
# @param enforce Enforce file permissions
# @param defaults File permissions
# @param file_params
#   Extra attributes for individual files, keyed by path.  Applied on top of
#   `defaults` and the fact's attributes (`ensure` included), and only to files
#   listed in `files`.  Set it through Hiera, which deep-merges it with the
#   module's default; a value passed in a resource-like class declaration
#   replaces that default.
#
#   `/boot/grub2/grubenv` ignores the SELinux defaults: GRUB replaces the file
#   after each boot (`grub2-set-bootflag` runs from a systemd user unit), so it
#   takes the logged-in session's SELinux user, and Puppet would otherwise set
#   it back to `system_u` after every reboot.  Ignoring the defaults leaves the
#   whole label unmanaged, so the type is pinned back to `boot_t`; only the
#   user, role and range go unmanaged.  Owner, group and mode are still
#   managed.  The pin also overrides a local `semanage fcontext` rule for
#   `grubenv`; a site with one sets `seltype` here to match it.
#
# @example
#   include simp_enterprise_el::grub
class simp_enterprise_el::grub (
  Hash                                   $defaults,
  Boolean                                $enforce,
  Hash[Stdlib::Unixpath, Hash]           $file_params,
  Optional[Hash[Stdlib::Unixpath, Hash]] $files = $facts['simp_enterprise_el__grub'],
) {
  $noop = $enforce ? {
    true    => {},
    default => { 'noop' => true },
  }

  $files.lest || { {} }.each |$key, $value| {
    simp_enterprise_el::resource::file { $key:
      params => $defaults + $value + ($file_params[$key].lest || { {} }) + $noop,
    }
  }
}
