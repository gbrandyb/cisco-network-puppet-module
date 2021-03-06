# Manages execuration for Aaa Authorization Login Exec Service.
#
# June 2018
#
# Copyright (c) 2013-2018 Cisco and/or its affiliates.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

Puppet::Type.newtype(:cisco_aaa_authorization_login_exec_svc) do
  @doc = "Manages execuration for Authorization Login Exec Service.

~~~puppet
  cisco_aaa_authorization_login_exec_svc {'[console|default]':
    ..attributes..
  }
~~~

  'console' and 'default' are the only services execurable.

  Example:
~~~puppet
    cisco_aaa_authorization_login_exec_svc {'console':
      ensure    => present,
      groups    => ['group1', 'group2'],
      method    => 'local',
    }
~~~"

  apply_to_all
  ensurable

  ###################
  # Resource Naming #
  ###################

  # Parse out the title to fill in the attributes in these patterns.
  # These attributes can be overwritten later.
  def self.title_patterns
    identity = ->(x) { x }
    patterns = []

    patterns << [
      /^(\S+)$/,
      [
        [:name, identity]
      ],
    ]
    patterns
  end

  newparam(:name, namevar: true) do
    desc 'Name of the exec login service. Valid values are "console" or "default".'

    validate do |value|
      fail unless value == 'default' || value == 'console'
    end
  end

  ##############
  # Attributes #
  ##############

  newproperty(:groups, array_matching: :all) do
    desc "Tacacs+ groups execured for this service. Valid values are
          an array of strings, keyword 'default'."

    validate do |val|
      unless val.kind_of?(Symbol)
        val.split.each do |group|
          fail "group #{value} must be a String" unless
            group.kind_of?(String)
        end
      end
    end

    munge do |val|
      val == 'default' ? :default : val
    end

    def in_sync?(is)
      (is.size == should.flatten.size && is.sort == should.flatten.sort)
    end
  end

  newproperty(:method) do
    desc "Authentication methods on this device. Valid values are 'local',
      'unselected', 'default'."

    newvalues(:local, :unselected, :default)
  end

  ################
  # Autorequires #
  ################

  # At a minimum, tacacs_server must be enabled to use these features
  autorequire(:cisco_tacacs_server) do |rel_catalog|
    rel_catalog.catalog.resource('Cisco_tacacs_server', 'default')
  end

  # Autorequire all cisco_aaa_group_tacacs associated with this service
  autorequire(:cisco_aaa_group_tacacs) do |rel_catalog|
    groups = []
    if self[:groups]
      self[:groups].flatten.each do |group|
        groups << rel_catalog.catalog.resource('Cisco_aaa_group_tacacs',
                                               "#{group}")
      end
    end
    groups
  end
end
