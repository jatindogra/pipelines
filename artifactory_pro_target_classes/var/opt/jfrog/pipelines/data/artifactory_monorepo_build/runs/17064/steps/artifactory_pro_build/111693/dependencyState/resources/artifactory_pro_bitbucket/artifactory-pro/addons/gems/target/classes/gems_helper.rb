#be aware how the scripting container is created in terms of LocalContextScope and LocalVariableBehavior,
#in accordance with local variables (@) and concurrency

require 'rubygems/package'

module Gems
  class Helper

    def spec(gem_file)
      Gem::Package.new(gem_file).spec
    end

    def name_version_platform(gem_file)
      spec = Gem::Package.new(gem_file).spec
      spec.name + ',' + spec.version.to_s + ',' + (spec.platform.nil? ? '' : spec.platform.to_s)
    end

    def gemspec_rz(gem_file, dest)
      open(dest.to_s, 'wb') { |file| file.write(Gem.deflate Marshal.dump spec(gem_file)) }
    end

    def reindex(nvps, dest)
      release_specs=[]
      latest_specs=[]
      prerelease_specs=[]

      nvps.each do |nvp|
        name = nvp.name
        version = Gem::Version.new(nvp.version)
        platform = nvp.platform
        platform = Gem::Platform::RUBY if nvp.platform.nil? or nvp.platform.empty?
        new_entry = [name, version, platform]

        if version.prerelease?
          prerelease_specs << new_entry
        else
          release_specs << new_entry
        end
      end

      release_specs.group_by{|n,v,p| n}.each{|k,g| g.group_by{|n,v,p| p}.each{|k,g| latest_specs<<g.max_by{|n,v,p| v}}}

      open(dest + "/specs.4.8.gz", 'wb') {|f| f << Marshal.dump(release_specs)}
      open(dest + "/latest_specs.4.8.gz", 'wb') {|f| f << Marshal.dump(latest_specs)}
      open(dest + "/prerelease_specs.4.8.gz", 'wb') {|f| f << Marshal.dump(prerelease_specs)}
    end

    def build_dependencies_result(nvprs)
      res=[]
      nvprs.each do |nvpr|
        platform = nvpr.platform
        platform = Gem::Platform::RUBY if platform.nil? or platform.empty?
        deps = nvpr.requirements.split('; ').to_a.map {|w| w.split(' ', 2)}.to_a
        res << {:name => nvpr.name, :number => nvpr.version, :platform => platform, :dependencies => deps}
      end
      data=Marshal.dump res
      data.to_java_bytes
    end

    def get_dependencies(gemspec_file)
      spec = Marshal.load Gem.inflate File.read gemspec_file
      spec.dependencies.select {|d| d.type == :runtime}.map {|d| [d.name + ' ' + d.requirement.to_s]}.join('; ')
    end

    def get_gemfile_dependencies(gem_file)
      spec = spec gem_file
      spec.dependencies.select {|d| d.type == :runtime}.map {|d| [d.name + ' ' + d.requirement.to_s]}.join('; ')
    end

    def get_licenses(gem_file)
      spec = Gem::Package.new(gem_file).spec
      spec.licenses
    end

    def nvp_to_ruby(nvp)
      platform = nvp.platform
      platform = Gem::Platform::RUBY if nvp.platform.nil? or nvp.platform.empty?
      version = Gem::Version.new nvp.version
      [nvp.name, version, platform]
    end

  end
end
Gems::Helper
