
module Geos::Helper
	JS_ESCAPE_MAP = {
		'\\'    => '\\\\',
		'</'    => '<\/',
		"\r\n"  => '\n',
		"\n"    => '\n',
		"\r"    => '\n',
		'"'     => '\\"',
		"'"     => "\\'"
	}

	# Escape carrier returns and single and double quotes for JavaScript
	# segments. Borrowed from ActiveSupport.
	def self.escape_javascript(javascript) #:nodoc:
		if javascript
			javascript.gsub(/(\\|<\/|\r\n|[\n\r"'])/) { JS_ESCAPE_MAP[$1] }
		else
			''
		end
	end

    def self.camelize(lower_case_and_underscored_word, first_letter_in_uppercase = false)
		if first_letter_in_uppercase
			lower_case_and_underscored_word.to_s.gsub(/\/(.?)/) { "::#{$1.upcase}" }.gsub(/(?:^|_)(.)/) { $1.upcase }
		else
			lower_case_and_underscored_word.to_s[0..0].downcase + camelize(lower_case_and_underscored_word, true)[1..-1]
		end
    end

    def self.xml_options(*args) #:nodoc:
		xml = if Builder::XmlMarkup === args.first
			args.first
		else
			Builder::XmlMarkup.new(:indent => 4)
		end

		options = if Hash === args.last
			args.last
		else
			Hash.new
		end

		[ xml, options ]
	end

	def self.number_with_precision(number, precision = 6)
		rounded_number = (Float(number) * (10 ** precision)).round.to_f / 10 ** precision
		"%01.#{precision}f" % rounded_number
	end
end
