# Create PRS directory
directory node['ibmprs']['prs_dir'] do
  recursive true
  action :create
end

# Download the prs file
remote_file "#{node['ibmprs']['prs_dir']}/#{node['ibmprs']['prs']}" do
  source "#{node['ibmprs']['media_url']}/#{node['ibmprs']['prs']}"
  not_if { File.exist?("#{node['ibmprs']['prs_dir']}/#{node['ibmprs']['prs']}") }
  owner 'root'
  group 'root'
  mode '0755'
  action :create
end
# Download the prs patch file
remote_file "#{node['ibmprs']['prs_dir']}/#{node['ibmprs']['prs_patch']}" do
  source "#{node['ibmprs']['media_url']}/#{node['ibmprs']['prs_patch']}"
  not_if { File.exist?("#{node['ibmprs']['prs_dir']}/#{node['ibmprs']['prs_patch']}") }
  owner 'root'
  group 'root'
  mode '0755'
  action :create
end

# untar the prs tar file
execute 'untar_package' do
  command "tar -xf #{node['ibmprs']['prs_dir']}/#{node['ibmprs']['prs']}"
  cwd node['ibmprs']['prs_dir']
  not_if { File.exist?("#{node['ibmprs']['prs_dir']}/prereq_checker.sh") }
  user 'root'
  group 'root'
  umask '022'
  action :run
end
# untar the prs patch gz file
execute 'untar_patch' do
  command "tar -xzf #{node['ibmprs']['prs_dir']}/#{node['ibmprs']['prs_patch']}"
  cwd node['ibmprs']['prs_dir']
  not_if { File.exist?("#{node['ibmprs']['prs_dir']}/UNIX_Linux/NOD_07040000.cfg") }
  user 'root'
  group 'root'
  umask '022'
  action :run
end

template "#{node['ibmprs']['prs_dir']}/run_prs.sh" do
  source 'prs.sh.erb'
  not_if { File.exist?("#{node['ibmprs']['prs_dir']}/all_results.txt") }
  mode 0755
end

execute 'run_prs' do
  command "#{node['ibmprs']['prs_dir']}/run_prs.sh"
  cwd node['ibmprs']['prs_dir']
  user 'root'
  group 'root'
  not_if { File.exist?("#{node['ibmprs']['prs_dir']}/all_results.txt") }
  action :run
end

execute 'find_fails' do
  command "grep FAIL #{node['ibmprs']['prs_dir']}/all_results.txt>#{node['ibmprs']['prs_dir']}/FAIL.txt"
  cwd node['ibmprs']['prs_dir']
  user 'root'
  group 'root'
  not_if { File.exist?("#{node['ibmprs']['prs_dir']}/FAIL.txt") }
  action :run
end

# print out the FAIL file
results = "#{node['ibmprs']['prs_dir']}/FAIL.txt"
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
directory node['ibmprs']['prs_dir'] do
  recursive true
  action :nothing
end
