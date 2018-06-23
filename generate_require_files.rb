# frozen_string_literal: true

def directories_in(root)
  Dir.entries(root).sort.select do |entry|
    fully_qualified_entry = File.join(root, entry)
    File.directory?(fully_qualified_entry) && !['.', '..'].include?(entry.to_s)
  end
end

def files_in(root)
  Dir.entries(root).sort.reject do |entry|
    fully_qualified_entry = File.join(root, entry)
    File.directory?(fully_qualified_entry) || entry.to_s == 'all.rb' || entry[-3..-1] != '.rb'
  end
end

def recursive_files_in(root)
  full_paths = Dir.glob(File.join(root, '**', '*')).sort.reject do |entry|
    fully_qualified_entry = File.join(root, entry)
    File.directory?(fully_qualified_entry) || entry[-7..-1] == '/all.rb' || entry[-3..-1] != '.rb'
  end

  remove_path = root.split('/')[0..-2].join('/') + '/'
  full_paths.map { |full_path| full_path.gsub(remove_path, '') }
end

def write_require_file(root, require_prefix, require_directories, require_files)
  require_file_path = File.join(root, 'all.rb')
  File.open(require_file_path, 'w') do |file|
    file.write("# frozen_string_literal: true\n\n")
    file.write("# THIS FILE IS AUTOGENERATED AND SHOULD NOT BE MANUALLY MODIFIED\n\n")
    require_directories.each do |require_directory|
      file.write("require '#{require_prefix}/#{require_directory}/all'\n")
    end
    file.write("\n") unless require_directories.empty?
    require_files.each { |require_file| file.write("require '#{require_prefix}/#{require_file[0..-4]}'\n") }
  end
end

lib_directories = ['clean_architecture']
lib_directories.each do |lib_directory|
  root = File.join(__dir__, 'lib', lib_directory)
  subdirectories = directories_in(root)
  write_require_file(root, lib_directory, subdirectories, files_in(root))
  subdirectories.each do |subdirectory|
    fully_qualified_directory = File.join(root, subdirectory)
    write_require_file(fully_qualified_directory, lib_directory, [], recursive_files_in(fully_qualified_directory))
  end
end
