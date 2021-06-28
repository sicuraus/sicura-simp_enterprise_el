# frozen_string_literal: true

# @summary Collect information for compliance checks

Facter.add('simp_enterprise_el__facts') do
  confine kernel: 'Linux'

  setcode do
    begin
      retval = {}

      usernames = {}
      uids = {}

      retval['users'] = []
      File.readlines('/etc/passwd').each do |u|
        user = [:name, :passwd, :uid, :gid, :gecos, :dir, :shell].zip(u.chomp.split(':')).to_h

        next if user[:name] == '+' # Skip legacy entries

        [:uid, :gid].each do |id|
          user[id] = user[id].to_i
        end

        user.delete(:passwd) unless user[:passwd] == 'x'
        retval['users'] << user

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
      File.readlines('/etc/group').each do |g|
        group = [:name, :passwd, :gid, :mem].zip(g.chomp.split(':')).to_h

        next if group[:name] == '+' # Skip legacy entries

        group[:gid] = group[:gid].to_i
        group[:mem] = group[:mem].nil? ? [] : group[:mem].split(',')
        group.delete(:passwd) unless group[:passwd] == 'x'
        retval['groups'] << group

        # Check for duplicate group names
        if groupnames.key?(group[:name])
          retval['dups'] = {} if retval['dups'].nil?
          retval['dups']['groupname'] = {} if retval['dups']['groupname'].nil?
          retval['dups']['groupname'][group[:name]] = [groupnames[group[:name]]] if retval['dups']['groupname'][group[:name]].nil?
          retval['dups']['groupname'][group[:name]] << group
        else
          groupnames[group[:name]] = group
        end

        # Check for duplicate gids
        if gids.key?(group[:gid])
          retval['dups'] = {} if retval['dups'].nil?
          retval['dups']['gid'] = {} if retval['dups']['gid'].nil?
          retval['dups']['gid'][group[:gid]] = [gids[group[:gid]]] if retval['dups']['gid'][group[:gid]].nil?
          retval['dups']['gid'][group[:gid]] << group
        else
          gids[group[:gid]] = group
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
              next unless sb.ftype == 'file' || sb.ftype == 'directory'
              next unless dotfiles.include?(file) || (sb.mode & 0o22).positive?

              mask = (file == '.netrc') ? 0o77 : 0o22
              target_mode = '0' + (sb.mode & (mask ^ 0o777)).to_s(8)

              retval['dotfiles'] = {} if retval['dotfiles'].nil?
              retval['dotfiles'][fullpath] = {
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

      begin
        File.open('/etc/shadow', 'r') do |shadow|
          today = Time.now.localtime.to_i / 86_400

          shadow.readlines.each do |line|
            fields = line.split(':')

            next if fields[0] == '+' # Skip legacy entries

            # Check for empty passwords
            if fields[1].empty?
              retval['lock'] = [] if retval['lock'].nil?
              retval['lock'] << fields[0] if usernames.key?(fields[0])
              next
            end

            # Check for password last set in the future
            if fields[2].to_i > today + 1 && (fields[7].empty? || fields[7].to_i > today)
              retval['expire'] = [] if retval['expire'].nil?
              retval['expire'] << fields[0] if usernames.key?(fields[0])
            # If the password last set time is one day in the future,
            # we're probably seeing a timezone-related problem.
            elsif fields[2].to_i == today + 1
              Facter.warn("User #{fields[0]} password last set tomorrow.  Time zone issue?")
            end
          end
        end
      rescue => e
        # Expected failure for non-root users
        Facter.warn(e) if Process::UID.eid.zero?
      end

      begin
        mountpoints = Facter.value('mountpoints')

        mountpoints.each do |key, value|
          # btrfs subvolumes are listed in findmnt output the same way as bind mounts
          next if value['filesystem'] == 'btrfs'

          fsroot = Facter::Core::Execution.execute("findmnt -n -o fsroot '#{key}'", on_fail: nil)&.chomp
          next if fsroot.nil?
          next if fsroot == '/'

          retval['bind'] = {} if retval['bind'].nil?
          retval['bind'][key] = fsroot
        end

        mountpoints.each do |key, value|
          next if value['device'].nil?
          next unless %r{^/dev/}.match?(value['device'])

          device = value['device'].sub(%r{^/dev/}, '')

          def removable(path)
            File.read("#{path}/removable").chomp.to_i.positive?
          end

          if Dir.exist?("/sys/block/#{device}")
            retval['removable'] = {} if retval['removable'].nil?
            retval['removable'][key] = removable("/sys/block/#{device}")
            next
          end

          Dir.glob("/sys/block/*/#{device}").each do |p|
            retval['removable'] = {} if retval['removable'].nil?
            retval['removable'][key] = removable(p.sub(%r{/#{device}$}, ''))
            break
          end
        end
      rescue => e
        Facter.warn(e)
      end

      retval
    rescue => e
      Facter.warn(e)
      nil
    end
  end
end
