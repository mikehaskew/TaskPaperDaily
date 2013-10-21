require 'rubygems'
require 'date'
require 'chronic'

# First set the files to search/replace in
files = Dir["/home/elu3/Dropbox/TaskPaper/*.taskpaper"]
output = ""

@yesterday = Chronic.parse('yesterday').to_date
@today = Chronic.parse('today').to_date
@now = Time.new
@tomorrow = Chronic.parse('tomorrow').to_date
@current_week = Time.new.strftime("%W").to_i+1
@weekdays = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
@due_weeknumber = /@due\(kw([1-9]{1}|[0-4][0-9]{1}|5{1}[0-3]{1})\)/
@regex_due_date = /@due\([0-9]{4}-(0[1-9]|1[0-2])-(0[1-9]|[1-2][0-9]|3[0-1])\)/

files.each do |file_name|
	infile = File.new(file_name)
	puts "test"
	#output = "Last run at #{@today}\n\n"
	first_line = 0
	while(!infile.eof?) do
		line = infile.gets

		if first_line == 0
			unless line.gsub!(/^Last run at(.*)$/, "Last run at #{@now}\n\n")
				output = "Last run at #{@today}\n\n"
			end
			first_line = 1
		end

		if !line.include? "@done"

			# remove relative dates if abolute dates are given
			if line.include? "@due"
				line.gsub!("@today", "")
				line.gsub!("@tomorrow", "")
				line.gsub!("@overdue", "")
			# set absolut date
			else
				line.gsub!("@today", "@due(#{@today})")
				line.gsub!("@tomorrow", "@due(#{@tomorrow})")

			end


			unless line.include? "@done"

				# get absolute date for weekdays
				unless line.index(@regex_due_date)
					line.gsub!(/@due\([^\)]*\)/) do |match|
						begin
							due_string = match[/@due\((.*)\)/, 1]
							due_date = Chronic.parse(due_string).to_date.to_s
							match += " @due(#{due_date})"
						rescue
							match
						end
					end
				end

				# set relative dates
				line.gsub!(@regex_due_date) do |match|
					begin
						date = DateTime.parse(match)
						if date < @today
							match += " @overdue"
						elsif date == @today
						 	match += " @today"
						elsif date == @tomorrow
						 	match += " @tomorrow"
						end
					rescue
						match
					end
				end
			end

			# remove weekday when duedate is tomorow
			if line.include? "@due(#{@tomorrow})"
				@weekdays.any? do |day|
					if line.include? "@due(#{day})"
						line.gsub!("@due(#{day})", "")
					end
				end
			end

			# handle calender weeks
			line.gsub!(@due_weeknumber) do |match|
				weeknumber = match[/@due\(kw(.*)\)/, 1]
				if weeknumber.length == 1
					weeknumber = "0#{weeknumber}"
				end

				if @current_week == weeknumber.to_i or @current_week == weeknumber.to_i+1

					if Time.parse("#{@tomorrow}").strftime("%W").to_i  == weeknumber.to_i+1
						match += " @tomorrow"
					else @current_week == weeknumber.to_i
						match += " @today"
					end
				elsif @current_week > weeknumber.to_i
					match += " @overdue"
				end
				match
			end
		end

		output+=line.rstrip + "\n"
	end
	infile.close
	File.open(file_name, "w") { |file| file.puts output }
	output = ""
end