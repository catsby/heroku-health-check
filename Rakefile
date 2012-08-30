desc "Revendor gems"
task :revendor do
  FileUtils.rm_rf(File.join(File.dirname(__FILE__), "vendor"))
  %w{dalli redis}.each do |gem|
    system("gem unpack #{gem} --target=vendor")
  end
end

task :default => :revendor
