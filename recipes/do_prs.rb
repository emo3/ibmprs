# Install the RHEL package bc
package %w(bc)

# Create PRS directory
directory node['nc_base']['prs_dir'] do
  recursive true
  action :create
end

# Download the prs file
remote_file "#{node['nc_base']['prs_dir']}/#{node['nc_base']['prs']}" do
  source "#{node['nc_base']['media_url']}/#{node['nc_base']['prs']}"
  not_if { File.exist?("#{node['nc_base']['prs_dir']}/#{node['nc_base']['prs']}") }
  owner 'root'
  group 'root'
  mode '0755'
  action :create
end
# Download the prs patch file
remote_file "#{node['nc_base']['prs_dir']}/#{node['nc_base']['prs_patch']}" do
  source "#{node['nc_base']['media_url']}/#{node['nc_base']['prs_patch']}"
  not_if { File.exist?("#{node['nc_base']['prs_dir']}/#{node['nc_base']['prs_patch']}") }
  owner 'root'
  group 'root'
  mode '0755'
  action :create
end

# untar the prs tar file
execute 'untar_package' do
  command "tar -xf #{node['nc_base']['prs_dir']}/#{node['nc_base']['prs']}"
  cwd node['nc_base']['prs_dir']
  not_if { File.exist?("#{node['nc_base']['prs_dir']}/prereq_checker.sh") }
  user 'root'
  group 'root'
  umask '022'
  action :run
end
# untar the prs patch gz file
execute 'untar_patch' do
  command "tar -xzf #{node['nc_base']['prs_dir']}/#{node['nc_base']['prs_patch']}"
  cwd node['nc_base']['prs_dir']
  not_if { File.exist?("#{node['nc_base']['prs_dir']}/UNIX_Linux/NOD_07040000.cfg") }
  user 'root'
  group 'root'
  umask '022'
  action :run
end

selinux_state 'SELinux Permissive' do
  not_if { File.exist?("#{node['nc_base']['prs_dir']}/all_results.txt") }
  action :permissive
end

template "#{node['nc_base']['prs_dir']}/run_prs.sh" do
  source 'prs.sh.erb'
  not_if { File.exist?("#{node['nc_base']['prs_dir']}/all_results.txt") }
  mode 0755
end

execute 'run_prs' do
  command "#{node['nc_base']['prs_dir']}/run_prs.sh"
  cwd node['nc_base']['prs_dir']
  user 'root'
  group 'root'
  not_if { File.exist?("#{node['nc_base']['prs_dir']}/all_results.txt") }
  action :run
end

execute 'find_fails' do
  command "grep FAIL #{node['nc_base']['prs_dir']}/all_results.txt>#{node['nc_base']['prs_dir']}/FAIL.txt"
  cwd node['nc_base']['prs_dir']
  user 'root'
  group 'root'
  not_if { File.exist?("#{node['nc_base']['prs_dir']}/FAIL.txt") }
  action :run
end

selinux_state 'SELinux Enforcing' do
  not_if { File.exist?("#{node['nc_base']['prs_dir']}/all_results.txt") }
  action :enforcing
end

# print out the FAIL file
results = "#{node['nc_base']['prs_dir']}/FAIL.txt"
ruby_block 'list_results' do
  only_if { ::File.exist?(results) }
  block do
    print "\n"
    File.open(results).each do |line|
      print line
    end
  end
end

# I do not clean up after the run
# just in case you want to examine the results
directory node['nc_base']['prs_dir'] do
  recursive true
  action :nothing
end
