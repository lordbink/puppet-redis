require 'spec_helper'

describe 'redis::sentinel' do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }
      let(:config_file_orig) do
        case facts[:osfamily]
        when 'Archlinux'
          '/etc/redis/redis-sentinel.conf.puppet'
        when 'Debian'
          '/etc/redis/redis-sentinel.conf.puppet'
        when 'Suse'
          '/etc/redis/redis-sentinel.conf.puppet'
        when 'FreeBSD'
          '/usr/local/etc/redis-sentinel.conf.puppet'
        when 'RedHat'
          '/etc/redis-sentinel.conf.puppet'
        end
      end

      describe 'without parameters' do
        let(:expected_content) do
          <<CONFIG
port 26379
dir /tmp
daemonize #{facts[:osfamily] == 'RedHat' ? 'no' : 'yes'}
pidfile /var/run/redis/redis-sentinel.pid

sentinel monitor mymaster 127.0.0.1 6379 2
sentinel down-after-milliseconds mymaster 30000
sentinel parallel-syncs mymaster 1
sentinel failover-timeout mymaster 180000

loglevel notice
logfile /var/log/redis/redis.log
CONFIG
        end

        it { is_expected.to create_class('redis::sentinel') }

        it {
          is_expected.to contain_file(config_file_orig).
            with_ensure('file').
            with_mode('0644').
            with_owner('redis').
            with_content(expected_content)
        }

        it {
          is_expected.to contain_service('redis-sentinel').
            with_ensure('running').
            with_enable('true')
        }

        if facts[:os]['family'] == 'Debian'
          it { is_expected.to contain_package('redis-sentinel').with_ensure('present') }
        else
          it { is_expected.not_to contain_package('redis-sentinel') }
        end
      end

      describe 'with custom parameters' do
        let(:params) do
          {
            auth_pass: 'password',
            sentinel_bind: '192.0.2.10',
            master_name: 'cow',
            down_after: 6000,
            log_file: '/tmp/barn-sentinel.log',
            failover_timeout: 28_000,
            notification_script: 'bar.sh',
            client_reconfig_script: 'foo.sh'
          }
        end

        let(:expected_content) do
          <<CONFIG
bind 192.0.2.10
port 26379
dir /tmp
daemonize #{facts[:osfamily] == 'RedHat' ? 'no' : 'yes'}
pidfile /var/run/redis/redis-sentinel.pid

sentinel monitor cow 127.0.0.1 6379 2
sentinel down-after-milliseconds cow 6000
sentinel parallel-syncs cow 1
sentinel failover-timeout cow 28000
sentinel auth-pass cow password
sentinel notification-script cow bar.sh
sentinel client-reconfig-script cow foo.sh

loglevel notice
logfile /tmp/barn-sentinel.log
CONFIG
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to create_class('redis::sentinel') }
        it { is_expected.to contain_file(config_file_orig).with_content(expected_content) }
      end
    end
  end
end
