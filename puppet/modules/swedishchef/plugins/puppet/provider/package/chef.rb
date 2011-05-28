# I tried namespacing this like 'swedischef::package' but puppet has some
# trouble with that and reports: 
#   Could not autoload swedishchef::package: wrong constant name
#   Swedishchef::package
#

require "rubygems"
require 'puppet/provider/package'

Puppet::Type.type(:package).provide(:chef, :parent => Puppet::Provider::Package) do
  desc "Whatever"

  def self.setup_chef
    require "chef"
    require "chef/client"
    require "chef/run_context"

    Chef::Config[:solo] = true
    Chef::Config[:log_level] = :info
    Chef::Log.level(:info)

    notice("Initializing chef...")
    chef_client = Chef::Client.new
    chef_client.run_ohai
    chef_client.build_node
    @@chef_context = Chef::RunContext.new(chef_client.node,
                                          Chef::CookbookCollection.new)

  end # def self.setup_chef

  # initialize a chef context, see above.
  setup_chef

  # Uhh.. what should we return here?
  def self.instances
    return []
  end # def self.instances

  def query
    return {}
  end

  def install
    chefpackage = Chef::Resource::Package.new(resource[:name], @@chef_context)
    chefpackage.version = resource[:ensure] if resource[:ensure] != :present
    chefpackage.run_action(:install)
  end # def create

  def update
    self.install
  end

  def uninstall
    chefpackage = Chef::Resource::Package.new(resource[:name], @@chef_context)
    chefpackage.run_action(:remove)
  end # def destroy

  def exists?
    # Fake exists? so we always run chef.
    # Return 'true' if ensure => absent (to force 'destroy')
    # Return 'false' otherwise (to force 'create')
    return @resource.should(:ensure) == :absent
  end

end # Puppet::Type :foo
