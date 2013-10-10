require 'json'

def file_list(path=".", offset=0, limit=-1)
	files = Dir["#{path}/*"].sort_by{|f| File.ctime(f)}

	result = []

	current_offset = 0

	files.each do |file|
		if File.file? file
			result << file
		else
			result << file_list(file)
		end

		current_offset += 1

		result.flatten!

		break if (result.count > limit and limit > 0)
	end

	result[offset..limit]
end

path, offset, limit = ARGV
list = file_list(path, offset.to_i, limit.to_i)
puts JSON.generate(list)
puts list.count