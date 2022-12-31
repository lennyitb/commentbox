module CommentBoxStyles
private
	DefaultParams = {
		style:       :stub,
		padding:     4,
		stretch:     0,
		offset:      2,
		spacelines:  true,
		alignment:  :left
	}
	Styles = {
		stub: {
			hlines: '**',
			oddlines: ['\\ ', ' \\'],
			evenlines: ['/ ', ' /'],
			oddcorners: ['=/','/=']
		},
		bars: {
			hlines: '==',
			oddlines: ['||', '||'],
			evenlines: ['||', '||'],
			oddcorners: ['/#','#/']
		},
		zigzag: {
			hlines: '=-',
			oddlines: ['\\ ', ' \\'],
			evenlines: ['/ ', ' /'],
			oddcorners: ['=O','O-']
		},
		money: {
			hlines: '><',
			oddlines: ['$!', '$!'],
			evenlines: ['!$', '!$'],
			oddcorners: ['>X','X<']
		}
	}
end


module CommentBoxIntegerExtensions
	def is_even?
		self % 2 == 0
	end
end
module CommentBoxStringExtensions
	Integer.prepend CommentBoxIntegerExtensions
	def justify_to (length)
		self << ' ' * (length - self.length)
	end
	def right_justify_to (length)
		(' ' * (length - self.length)) + self
	end
	def center_align (length)
		if !length.is_even? then raise 'String#center_align : length must be even' end
		llength = ((length - self.length) / 2)
		rlength = llength
		if !self.length.is_even? then rlength += 1 end
		(' ' * llength) + self + (' ' * rlength)
	end
	def align_to (side, length)
		if side == :left
			self.justify_to length
		elsif side == :right
			self.right_justify_to length
		elsif side == :center
			self.center_align length
		else
			raise 'String#align_to : expected :left, :right, or :center here'
		end
	end
end

class CommentBox
	String.prepend CommentBoxStringExtensions # string align/justify methods
	Integer.prepend CommentBoxIntegerExtensions # integer is_even? method
	include CommentBoxStyles
	
	attr_writer :padding, :spacelines, :alignment, :offset
	# I don't know how to call param= methods from the inside so I just use a set_param in private
	def text= (value); set_text value; self end; def alignment= (value); set_alignment value; self end
	def style= (value); @style = Styles[value]; self end
	# there is no @stretch, stretch is just added to @max_line_length
	# but, if stretch= is called, then @max_line_length must be recalculated
	def stretch= (value); @max_line_length = @text.map(&:length).max + value; self end

	def initialize (params) # params: {text: String or Array, style: Symbol, padding: Integer, spacelines: Boolean, alignment: Symbol or Array}
		# for now require an argument of some sort
		if params.class != Hash && params.class != String then raise 'CommentBox#initialize : you gotta initialize this with Hash or String.' end
		
		# if it's not a hash, then make it one.
		if params.is_a? String then params = {text: params} end 

		# fill in a bunch of instance variables from params or default values
		style_symbol = params[:style] || DefaultParams[:style]; @style = Styles[style_symbol]
		@padding = params[:padding] || DefaultParams[:padding]
		@offset = params[:offset] || DefaultParams[:offset]
		# one of the options for this is false, so it's not gonna play nice with ||
		@spacelines = (params[:spacelines] != nil) ? params[:spacelines] : DefaultParams[:spacelines] 

		# call on some special methods to parse text and alignment
		set_text params[:text]
		set_alignment params[:alignment]	
		@max_line_length += (params[:stretch] || DefaultParams[:stretch]).to_i
	end
	def to_s
		spaceLine = @spacelines ? [@style[:oddlines][0], ' ' * (@max_line_length + @padding * 2), @style[:oddlines][1], "\n"].join : ''
		
		# construct an array of lines, join them together and return
		return [
			t_line(:begin),
			spaceLine,
			(0..@text.size - 1).map { |line| fmt_text_line line }, # this is a nested array and must be flattened
			spaceLine,
			t_line(:end)
		# flatten, add offset to each line if it's not empty, join them together, and remove trailing newline
		].flatten.map { |line| line == '' ? '' : (' ' * @offset) << line}.join.chomp 
	end

private
	def set_text (string)
		if string.is_a? String
			@text = string.split "\n"
		elsif string.is_a? Array
			@text = string
		else
			raise 'CommentBox#text= : expected String or Array here'
		end
		@max_line_length = @text.map(&:length).max
		if !@max_line_length.is_even? then @max_line_length += 1 end
		insert_line_if_even
	end
	def set_alignment (align)
		if align == nil
		# set default value if no argument is given
			@alignment = [ DefaultParams[:alignment] ] * (@text.size)
		else
		# fill array with align if one symbol is given
			if align.is_a? Symbol
				@alignment = [ align ] * (@text.size)
		# set @alignment directly if an array is given
			elsif align.is_a? Array
		# if the array is too short, fill it with the last element
				if align.size < @text.size then (@text.size - align.size).times { align.push align.last } end
				@alignment = align
			else
				raise 'CommentBox#alignment= : expected Symbol or Array here'
			end
		end
		# if the number of lines is even, insert a blank line between the first and second lines
		insert_line_if_even
	end
	def insert_line_if_even # also will delete a blank line if there is one
		# stop this function from raising errors we don't really care about if the instance isn't fully constructed yet 
		if !(@text.is_a?(Array) && @alignment.is_a?(Array)) then return end

		if @text.size.is_even?
			if @text[1] == '' then @text.delete_at 1; @alignment.delete_at 1
			else @text.insert(1,''); @alignment.insert(1,:left) end
		end
	end
	def t_line (beginOrEnd)
		if beginOrEnd == :begin
			bchar = '/*'; echar = @style[:oddcorners][0]
		else
			bchar = @style[:oddcorners][1]; echar = '*/'
		end
		[bchar, @style[:hlines] * ((@max_line_length + @padding * 2) / 2), echar, "\n"].join
	end
	def fmt_text_line(line)
	# justify the text
		text = @text[line].align_to @alignment[line], @max_line_length
	# pad the text
		ret = (' ' * @padding) + (text) + (' ' * @padding)
	# if there are no spacing lines, then even lines are odd & vice versa
		line += (@spacelines ? 0 : 1)
	# add border characters (according to @style) into even/odd lines respectively
		if line.is_even? then @style[:evenlines][0] + ret + @style[:evenlines][1] + "\n"
		else @style[:oddlines][0] + ret + @style[:oddlines][1] + "\n" end
	end
end

puts CommentBox.new "Lenny's box"