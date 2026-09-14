# frozen_string_literal: true

# @summary Strip the bits in `mask` from a file mode
#
# Both arguments are octal strings, as reported by `simp_enterprise_el__facts`
# and as set in compliance data.  The result is limited to the permission
# bits: setuid, setgid and sticky are always cleared, matching what the
# `dotfiles` fact did when it computed the target mode itself.
#
# @example
#   simp_enterprise_el::apply_mask('0777', '0133') # => '0644'
Puppet::Functions.create_function(:'simp_enterprise_el::apply_mask') do
  # @param mode The current mode, e.g. `'0755'` or `'1777'`
  # @param mask The bits to clear, e.g. `'0022'`
  # @return [String] `mode` with the `mask` bits cleared, as a four digit octal string
  dispatch :apply_mask do
    param 'Pattern[/\A[0-7]{3,4}\z/]', :mode
    param 'Simp_enterprise_el::Mask', :mask
    return_type 'String'
  end

  def apply_mask(mode, mask)
    '%04o' % (mode.to_i(8) & (0o777 ^ mask.to_i(8)))
  end
end
