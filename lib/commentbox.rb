
module CommentBoxStyles
	DefaultParams = {
		style:       :stub,
		padding:     4,
		stretch:     0,
		offset:      2,
		min_width:   0,
		spacelines:  true,
		alignment:   :left
	}
	Styles = {
		stub: {
			hlines: '**',
			oddlines: ['\\ ', ' \\'],
			evenlines: ['/ ', ' /'],
			oddcorners: ['=/','/=']
		},
		window: {
			hlines: '**',
			oddlines: ['\\*', '*\\'],
			evenlines: ['/+', '+/'],
			oddcorners: ['+/','/+']
		},
		parallax: {
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
	@@default_params = CommentBoxStyles::DefaultParams
	@@styles = CommentBoxStyles::Styles

	# class methods for messing with default values
	# make sure everything is symbolized that needs to be
	def self.default_params; @@default_params end
	def self.default_params=(value); @@default_params = value.transform_keys(&:to_sym) end
	# def self.default_params[]= (key, value); @@default_params[key.to_sym] = value end
	def self.set_default_params (value = {}); value.each { |key, val| @@default_params[key.to_sym] = val } end
	def self.styles; @@styles end
	def self.add_style(value)
		value.each do |key, val|
			if val[:default] || val[:default?] 
				@@default_params[:style] = key
				break # set the first default we find and stop the madness immediately
			end
		end
		# I could attempt to remove a :default? key here but it doesn't matter
		# this is a terse one but trust me
		@@styles.merge! value.transform_keys(&:to_sym).transform_values { |v| v.transform_keys(&:to_sym) }
	end
	
	# instance setter methods
	attr_writer :padding, :spacelines, :alignment, :offset
	# I don't know how to call param= methods from the inside so I just use a set_param in private
	def text= (value); set_text value; self end;
	def alignment= (value); set_alignment value; self end
	def style= (value); set_style value; self end
	# there is no @stretch, stretch is just added to @max_line_length
	# but, if stretch= is called, then @max_line_length must be recalculated
	def stretch= (value)
		@max_line_length = @text.map(&:length).max + value
		if !@max_line_length.is_even? then @max_line_length += 1 end
	self end

	# needs more reliance on setter methods. changing instance variables after initialization is a total house of cards right now
	def initialize (params) # params: {text: String or Array, style: Symbol, padding: Integer, spacelines: Boolean, alignment: Symbol or Array, and some others}
		# for now require an argument of some sort
		if params.class != Hash && params.class != String then raise 'CommentBox#initialize : you gotta initialize this with Hash or String.' end
		
		# if it's not a hash, then make it one.
		if params.is_a? String then params = {text: params} end 

		# fill in a bunch of instance variables from params or default values
		@padding = (params[:padding] || @@default_params[:padding]).to_i
		@offset = (params[:offset] || @@default_params[:offset]).to_i
		# one of the options for this is false, so it's not gonna play nice with ||
		@spacelines = (params[:spacelines] != nil) ? params[:spacelines] : @@default_params[:spacelines] 
		@stretch = (params[:stretch] || @@default_params[:stretch]).to_i
		@min_width = (params[:min_width] || @@default_params[:min_width]).to_i

		# call on some special methods to parse text and alignment
		set_text params[:text]
		set_alignment params[:alignment]	
		set_style params[:style]
		# @max_line_length += (params[:stretch] || @@default_params[:stretch]).to_i
		if !@max_line_length.is_even? then @max_line_length += 1 end
	end
	def to_s
		# exact value of spaceLine is calculated if @spacelines is true, otherwise it's just an empty string
		spaceLine = @spacelines ? [@style[:oddlines][0], ' ' * (@max_line_length + @padding * 2), @style[:oddlines][1], "\n"].join : ''
		
		# construct an array of lines, join them together and return
		return [
			t_line(:begin),
			spaceLine,
			(0..@text.size - 1).map { |line| fmt_text_line line }, # this is a nested array and must be flattened
			spaceLine,
			t_line(:end)
		# flatten, map offset in front of each line if it's not empty, join them together, and remove trailing newline
		].flatten.map { |line| line == '' ? '' : (' ' * @offset) << line }.join.chomp 
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
		@max_line_length = @text.map(&:length).max + @stretch
		@max_line_length = @min_width unless @max_line_length > @min_width
		if !@max_line_length.is_even? then @max_line_length += 1 end
		insert_line_if_even
	end
	def set_alignment (align)
		if align == nil
		# set default value if no argument is given
			@alignment = [ @@default_params[:alignment] ] * (@text.size)
		else
		# fill array with align if one symbol is given
			if align.is_a? Symbol
				@alignment = [ align ] * (@text.size)
		# set @alignment directly if an array is given
			elsif align.is_a? Array
				align.map! { |a| a.to_sym }
		# if the array is too short, fill it with the last element
				if align.size < @text.size then (@text.size - align.size).times { align.push align.last } end
				@alignment = align
			elsif align.is_a? String
				@alignment = [ align.to_sym ] * (@text.size)
			else
				raise 'CommentBox#alignment= : expected Symbol, Array, or String here'
			end
		end
		# if the number of lines is even, insert a blank line between the first and second lines
		insert_line_if_even
	end
	def set_style (style)
		if style == nil then @style = @@styles[@@default_params[:style]]
		elsif style.is_a? Symbol then @style = @@styles[style]
		elsif style.is_a? Hash then @style = style
		elsif style.is_a? String then @style = @@styles[style.to_sym]
		else raise 'CommentBox#style= : expected Symbol, Hash, or String here' end
	end
	def insert_line_if_even # also will delete a blank line if there is one
		# stop this function from raising errors we don't really care about if the instance isn't fully constructed yet 
		if !(@text.is_a?(Array) && @alignment.is_a?(Array)) then return end

		if @text.size.is_even?
			if @text[1] == '' then @text.delete_at 1; @alignment.delete_at 1
			else @text.insert(1,''); @alignment.insert(1,:left) end
		end
	end
	def t_line (beginOrEnd) #t[erminating]_line: top or bottom (begin or end) of the box
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