# frozen_string_literal: true

# @summary Collect information for compliance checks

def passwd
  return @passwd unless @passwd.nil?

  @passwd = []
  File.readlines('/etc/passwd', chomp: true).each do |u|
    user = [:name, :passwd, :uid, :gid, :gecos, :dir, :shell].zip(u.split(':', 7)).to_h

    next if user[:name] == '+' # Skip legacy entries

    [:uid, :gid].each do |id|
      user[id] = user[id].to_i
    end

    user.delete(:passwd) unless user[:passwd] == 'x'

    @passwd << user
  end

  @passwd
end

def shadow
  return @shadow unless @shadow.nil?

  @shadow = []

  File.readlines('/etc/shadow', chomp: true).each do |s|
    entry = [:name, :passwd, :lstchg, :min, :max, :warn, :inact, :expire, :flag].zip(s.split(':', 9)).to_h

    next if entry[:name] == '+' # Skip legacy entries

    [:lstchg, :min, :max, :inact, :expire].each do |v|
      entry[v] = nil if entry[v].empty?
      entry[v] = entry[v].to_i unless entry[v].nil?
    end

    @shadow << entry
  end

  @shadow
rescue => e
  # Expected failure for non-root users
  Facter.warn(e) if Process::UID.eid.zero?
  []
end

# Shadow entries keyed by name.  A duplicated name keeps the *first* entry,
# which is the one getspnam(3) and the shadow tools (`passwd -l`) act on.
def shadow_by_name
  return @shadow_by_name unless @shadow_by_name.nil?

  @shadow_by_name = shadow.each_with_object({}) { |sp, h| h[sp[:name]] ||= sp }
end

def group
  return @group unless @group.nil?

  @group = []

  File.readlines('/etc/group', chomp: true).each do |g|
    entry = [:name, :passwd, :gid, :mem].zip(g.split(':', 4)).to_h

    next if entry[:name] == '+' # Skip legacy entries

    entry[:gid] = entry[:gid].to_i
    entry[:mem] = entry[:mem].nil? ? [] : entry[:mem].split(',')
    entry.delete(:passwd) unless entry[:passwd] == 'x'

    @group << entry
  end

  @group
end

# Login shells that count as valid for the "accounts without a valid login
# shell are locked" checks (CIS EL8/EL9/EL10 5.4.2.8).  Those build the set
# from /etc/shells with the `*/nologin` entries filtered out, so an account
# sitting on /sbin/nologin counts as having no valid login shell.
def valid_login_shells
  return @valid_login_shells unless @valid_login_shells.nil?

  @valid_login_shells = File.readlines('/etc/shells', chomp: true).map(&:strip).select do |line|
    line.start_with?('/') && File.basename(line) != 'nologin'
  end
rescue => e
  # An unreadable or missing /etc/shells leaves the set empty, which the
  # callers treat as "do not lock anything" rather than "nothing is valid".
  Facter.warn(e)
  @valid_login_shells = []
end

# Whether an account can log in interactively.  CIS scopes its home directory
# and dot file rules to "local interactive users", and a shared home (stock EL
# ships `operator` at /root and `nobody` at /) must only ever be judged
# against the account that can actually use it.  Falls back to a basename
# check when /etc/shells could not be read.
def login_shell?(shell)
  return false if shell.nil? || shell.empty?
  return valid_login_shells.include?(shell) unless valid_login_shells.empty?

  File.basename(shell) != 'nologin'
end

Facter.add('simp_enterprise_el__facts') do
  confine kernel: 'Linux'

  setcode do
    retval = {}

    usernames = {}
    uids = {}

    retval['users'] = []
    retval['non_system_users'] = []
    passwd.each do |user|
      retval['users'] << user
      unless user[:uid] < 1000 || user[:shell] == '/sbin/nologin'
        sp = shadow_by_name[user[:name]]
        next if sp.nil?
        user[:password_expiration] = sp[:expire]
        user[:password_inactive] = sp[:inact]
        retval['non_system_users'] << user
      end

      # Check for duplicate usernames
      if usernames.key?(user[:name])
        retval['dups'] = {} if retval['dups'].nil?
        retval['dups']['username'] = {} if retval['dups']['username'].nil?
        retval['dups']['username'][user[:name]] = [usernames[user[:name]]] if retval['dups']['username'][user[:name]].nil?
        retval['dups']['username'][user[:name]] << user
      else
        usernames[user[:name]] = user
      end

      # Check for duplicate uids
      if uids.key?(user[:uid])
        retval['dups'] = {} if retval['dups'].nil?
        retval['dups']['uid'] = {} if retval['dups']['uid'].nil?
        retval['dups']['uid'][user[:uid]] = [uids[user[:uid]]] if retval['dups']['uid'][user[:uid]].nil?
        retval['dups']['uid'][user[:uid]] << user
      else
        uids[user[:uid]] = user
      end
    end

    groupnames = {}
    gids = {}

    retval['groups'] = []
    group.each do |gr|
      retval['groups'] << gr

      # Check for duplicate gr names
      if groupnames.key?(gr[:name])
        retval['dups'] = {} if retval['dups'].nil?
        retval['dups']['groupname'] = {} if retval['dups']['groupname'].nil?
        retval['dups']['groupname'][gr[:name]] = [groupnames[gr[:name]]] if retval['dups']['groupname'][gr[:name]].nil?
        retval['dups']['groupname'][gr[:name]] << gr
      else
        groupnames[gr[:name]] = gr
      end

      # Check for duplicate gids
      if gids.key?(gr[:gid])
        retval['dups'] = {} if retval['dups'].nil?
        retval['dups']['gid'] = {} if retval['dups']['gid'].nil?
        retval['dups']['gid'][gr[:gid]] = [gids[gr[:gid]]] if retval['dups']['gid'][gr[:gid]].nil?
        retval['dups']['gid'][gr[:gid]] << gr
      else
        gids[gr[:gid]] = gr
      end
    end

    retval['users'].each do |user|
      if Dir.exist?(user[:dir])
        begin
          sb = File::Stat.new(user[:dir])
          # Enforce permissions on home directories
          current_mode = '0' + sb.mode.to_s(8)
          target_mode = '0' + (sb.mode & (0o27 ^ 0o777)).to_s(8)
          if (sb.uid != user[:uid] && sb.uid != 0) || current_mode != target_mode
            retval['homes'] = {} if retval['homes'].nil?
            retval['homes'][user[:dir]] = {
              'ensure' => sb.ftype,
              'owner'  => sb.uid.zero? ? sb.uid : user[:uid],
              'group'  => sb.gid.zero? ? sb.gid : user[:gid],
              'mode'   => target_mode,
            }
          end

          # Dot files are only judged against accounts that can log in: a
          # nologin account sharing a home (operator at /root, nobody at /)
          # would otherwise claim ownership of every file in it.
          if login_shell?(user[:shell])
            # Report every dot file and dot directory at the top level of the
            # home.  This is state only: which files are out of policy, and
            # what their mode should become, is decided by
            # simp_enterprise_el::dotfiles from its parameters, so that a
            # benchmark's mask and ownership rules apply only where its data
            # turns them on.  `owner` and `group` are the values the class
            # will set (the user and the user's primary group); `current` is
            # what is on disk.
            (Dir.entries(user[:dir]) - ['.', '..']).each do |file|
              next unless %r{^\.}.match?(file)

              fullpath = File.join(user[:dir], file)
              next if File.symlink?(fullpath)
              sb = File::Stat.new(fullpath)
              next unless ['file', 'directory'].include?(sb.ftype)

              retval['dotfiles'] = {} if retval['dotfiles'].nil?
              retval['dotfiles'][fullpath] = {
                'ensure'  => sb.ftype,
                'owner'   => user[:uid],
                'group'   => user[:gid],
                'current' => {
                  'owner' => sb.uid,
                  'group' => sb.gid,
                  'mode'  => '%04o' % (sb.mode & 0o7777),
                },
              }
            end

            # Enforce permissions on initialization files
            initialization_files = ['.cshrc', '.tcshrc', '.bashrc', '.bash_profile', '.bash_login', '.bash_logout', '.profile']

            (Dir.entries(user[:dir]) - ['.', '..']).each do |file|
              next unless initialization_files.include?(file)

              fullpath = File.join(user[:dir], file)
              next if File.symlink?(fullpath)
              sb = File::Stat.new(fullpath)
              next unless ['file', 'directory'].include?(sb.ftype)
              target_mode = '0' + (sb.mode & (0o27 ^ 0o777)).to_s(8)

              retval['initialization_files'] = {} if retval['initialization_files'].nil?
              retval['initialization_files'][fullpath] = {
                'ensure' => sb.ftype,
                'owner'  => user[:uid],
                'mode'   => target_mode,
              }
            end
          end
        rescue => e
          # Expected failure for non-root users
          Facter.warn(e) if Process::UID.eid.zero?
        end
      else
        # Check for missing home directories
        unless user[:uid].zero? && user[:name] != 'root'
          retval['homes'] = {} if retval['homes'].nil?
          retval['homes'][user[:dir]] = {
            'ensure' => 'directory',
            'owner'  => user[:uid],
            'group'  => user[:gid],
          }
        end
      end

      # Check for missing groups
      next if gids.key?(user[:gid]) || retval['missing_groups']&.any? { |_k, v| v['gid'] == user[:gid] }
      retval['missing_groups'] = {} if retval['missing_groups'].nil?
      retval['missing_groups'][user[:name]] = {
        'ensure' => 'present',
        'gid'    => user[:gid],
      }
    end

    today = Time.now.localtime.to_i / 86_400

    shadow.each do |sp|
      # Check for empty passwords
      if sp[:passwd].empty?
        retval['lock'] = [] if retval['lock'].nil?
        retval['lock'] << sp[:name] if usernames.key?(sp[:name])
        next
      end

      # Check for password last set in the future
      if sp[:lstchg].to_i > today + 1 && (sp[:expire].nil? || sp[:expire] > today)
        retval['expire'] = [] if retval['expire'].nil?
        retval['expire'] << sp[:name] if usernames.key?(sp[:name])
      # If the password last set time is one day in the future,
      # we're probably seeing a timezone-related problem.
      elsif sp[:lstchg] == today + 1
        Facter.warn("User #{sp[:name]} password last set tomorrow.  Time zone issue?")
      end
    end

    # Accounts that have no valid login shell but still have a usable
    # password (CIS 5.4.2.8).  This is kept apart from `lock`, which lists
    # empty-password accounts: the two are different rules, and
    # simp_enterprise_el::users enforces each behind its own parameter so
    # that enabling one never locks accounts on behalf of the other.
    #
    # Only accounts that are *currently* unlocked belong on this list:
    # simp_enterprise_el::users turns each entry into a bare
    # `exec { "/usr/bin/passwd -l <user>" }` with no guard, so an account that
    # stays listed after it has been locked makes every subsequent Puppet run
    # report a change.
    unless valid_login_shells.empty?
      passwd.each do |user|
        # The audit exempts root by name, and locking it is an outage.
        next if user[:name] == 'root'
        next if valid_login_shells.include?(user[:shell])

        sp = shadow_by_name[user[:name]]
        next if sp.nil?
        # Empty is 'NP', which the empty-password branch above already owns.
        next if sp[:passwd].empty?
        # '!' and '*' both report as 'L' from `passwd -S`.
        next if sp[:passwd].start_with?('!', '*')

        retval['lock_invalid_shell'] = [] if retval['lock_invalid_shell'].nil?
        retval['lock_invalid_shell'] << user[:name] unless retval['lock_invalid_shell'].include?(user[:name])
      end
    end

    retval
  rescue => e
    Facter.warn(e)
    nil
  end
end
