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
        sp = shadow.find { |entry| entry[:name] == user[:name] }
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

          # Enforce permissions on dot files
          dotfiles = ['.rhosts', '.netrc', '.forward']

          (Dir.entries(user[:dir]) - ['.', '..']).each do |file|
            next unless %r{^\.}.match?(file)

            fullpath = File.join(user[:dir], file)
            next if File.symlink?(fullpath)
            sb = File::Stat.new(fullpath)
            next unless ['file', 'directory'].include?(sb.ftype)
            next unless dotfiles.include?(file) || sb.mode.anybits?(0o22)

            mask = (file == '.netrc') ? 0o77 : 0o22
            target_mode = '0' + (sb.mode & (mask ^ 0o777)).to_s(8)

            retval['dotfiles'] = {} if retval['dotfiles'].nil?
            retval['dotfiles'][fullpath] = {
              'ensure' => sb.ftype,
              'owner'  => user[:uid],
              'mode'   => target_mode,
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

    retval
  rescue => e
    Facter.warn(e)
    nil
  end
end
