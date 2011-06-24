
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

  def self.escape_json(hash, ignore_keys = [])
    json = hash.inject([]) do |memo, (k, v)|
      memo.tap {
        k = k.to_s
        memo << if ignore_keys.include?(k)
          "#{k.to_json}: #{v}"
        else
          "#{k.to_json}: #{v.to_json}"
        end
      }
    end

    "{#{json.join(', ')}}"
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

  # Return a new Hash with all keys converted to camelized Strings.
  def self.camelize_keys(hash, first_letter_in_uppercase = false)
    hash.inject({}) do |options, (key, value)|
      options[camelize(key, first_letter_in_uppercase)] = value
      options
    end
  end

  # Destructively convert all keys to camelized Strings.
  def camelize_keys!(hash, first_letter_in_uppercase = false)
    hash.tap {
      hash.keys.each do |key|
        unless key.class.to_s == 'String'
          hash[camelize(key, first_letter_in_uppercase)] = hash[key]
          hash.delete(key)
        end
      end
    }
  end

  # Deeply camelize a Hash.
  def deep_camelize_keys(hash, first_letter_in_uppercase = false)
    camelize_keys(hash, first_letter_in_upppcase).inject({}) do |memo, (k, v)|
      memo.tap do
        if v.is_a? Hash
          memo[k] = deep_camelize_keys(v, first_letter_in_uppercase)
        else
          memo[k] = v
        end
      end
    end
  end

  # Destructively deeply camelize a Hash.
  def deep_camelize_keys!(hash, first_letter_in_uppercase = false)
    hash.replace(deep_camelize_keys(hash, first_letter_in_uppercase))
  end

  def self.number_with_precision(number, precision = 6)
    rounded_number = (Float(number) * (10 ** precision)).round.to_f / 10 ** precision
    "%01.#{precision}f" % rounded_number
  end
end
