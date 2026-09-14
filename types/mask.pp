# @summary Permission bits to strip from a file mode, as an octal string (e.g. `'0022'`, `'0133'`)
type Simp_enterprise_el::Mask = Pattern[/\A0?[0-7]{3}\z/]
