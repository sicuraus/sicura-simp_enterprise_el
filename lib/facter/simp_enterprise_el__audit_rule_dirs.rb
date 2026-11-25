# frozen_string_literal: true

# @summary Report whether each optional directory named by a compliance audit
#   rule exists
#
# The kernel rejects a `-F path=` audit rule whose directory is missing, and
# auditctl then exits non-zero even under `-c`, leaving audit-rules.service
# failed. These directories belong to optional packages (polkit, dbus-daemon,
# openssh, sssd, libutempter), so the CIS privileged-command checks that name
# them are confined on this fact.
#
# Every directory is always reported, as true or false: compliance_markup keeps
# a check whose confine fact is absent, so a missing key would not drop it.

SIMP_ENTERPRISE_EL__AUDIT_RULE_DIRS = [
  '/usr/lib/polkit-1',
  '/usr/libexec/dbus-1',
  '/usr/libexec/openssh',
  '/usr/libexec/sssd',
  '/usr/libexec/utempter',
].freeze

Facter.add('simp_enterprise_el__audit_rule_dirs') do
  confine kernel: 'Linux'

  setcode do
    SIMP_ENTERPRISE_EL__AUDIT_RULE_DIRS.to_h { |dir| [dir, File.directory?(dir)] }
  end
end
