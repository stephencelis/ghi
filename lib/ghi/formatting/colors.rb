module GHI
  module Formatting
    module Colors
      class << self
        attr_accessor :colorize
        def colorize?
          return @colorize if defined? @colorize
          @colorize = STDOUT.tty?
        end
      end

      def colorize?
        Colors.colorize?
      end

      def fg color, &block
        escape color, 3, &block
      end

      def bg color, &block
        fg(offset(color)) { escape color, 4, &block }
      end

      def bright &block
        escape :bright, &block
      end

      def underline &block
        escape :underline, &block
      end

      def blink &block
        escape :blink, &block
      end

      def inverse &block
        escape :inverse, &block
      end

      def highlight(code_block)
        highlighter.highlight(code_block)
      end

      def no_color
        old_colorize, Colors.colorize = colorize?, false
        yield
      ensure
        Colors.colorize = old_colorize
      end

      def to_hex string
        WEB[string] || string.downcase.sub(/^(#|0x)/, '').
          sub(/^([0-f])([0-f])([0-f])$/, '\1\1\2\2\3\3')
      end

      ANSI = {
        :bright    => 1,
        :underline => 4,
        :blink     => 5,
        :inverse   => 7,

        :black     => 0,
        :red       => 1,
        :green     => 2,
        :yellow    => 3,
        :blue      => 4,
        :magenta   => 5,
        :cyan      => 6,
        :white     => 7
      }

      WEB = {
        'aliceblue'            => 'f0f8ff',
        'antiquewhite'         => 'faebd7',
        'aqua'                 => '00ffff',
        'aquamarine'           => '7fffd4',
        'azure'                => 'f0ffff',
        'beige'                => 'f5f5dc',
        'bisque'               => 'ffe4c4',
        'black'                => '000000',
        'blanchedalmond'       => 'ffebcd',
        'blue'                 => '0000ff',
        'blueviolet'           => '8a2be2',
        'brown'                => 'a52a2a',
        'burlywood'            => 'deb887',
        'cadetblue'            => '5f9ea0',
        'chartreuse'           => '7fff00',
        'chocolate'            => 'd2691e',
        'coral'                => 'ff7f50',
        'cornflowerblue'       => '6495ed',
        'cornsilk'             => 'fff8dc',
        'crimson'              => 'dc143c',
        'cyan'                 => '00ffff',
        'darkblue'             => '00008b',
        'darkcyan'             => '008b8b',
        'darkgoldenrod'        => 'b8860b',
        'darkgray'             => 'a9a9a9',
        'darkgrey'             => 'a9a9a9',
        'darkgreen'            => '006400',
        'darkkhaki'            => 'bdb76b',
        'darkmagenta'          => '8b008b',
        'darkolivegreen'       => '556b2f',
        'darkorange'           => 'ff8c00',
        'darkorchid'           => '9932cc',
        'darkred'              => '8b0000',
        'darksalmon'           => 'e9967a',
        'darkseagreen'         => '8fbc8f',
        'darkslateblue'        => '483d8b',
        'darkslategray'        => '2f4f4f',
        'darkslategrey'        => '2f4f4f',
        'darkturquoise'        => '00ced1',
        'darkviolet'           => '9400d3',
        'deeppink'             => 'ff1493',
        'deepskyblue'          => '00bfff',
        'dimgray'              => '696969',
        'dimgrey'              => '696969',
        'dodgerblue'           => '1e90ff',
        'firebrick'            => 'b22222',
        'floralwhite'          => 'fffaf0',
        'forestgreen'          => '228b22',
        'fuchsia'              => 'ff00ff',
        'gainsboro'            => 'dcdcdc',
        'ghostwhite'           => 'f8f8ff',
        'gold'                 => 'ffd700',
        'goldenrod'            => 'daa520',
        'gray'                 => '808080',
        'green'                => '008000',
        'greenyellow'          => 'adff2f',
        'honeydew'             => 'f0fff0',
        'hotpink'              => 'ff69b4',
        'indianred'            => 'cd5c5c',
        'indigo'               => '4b0082',
        'ivory'                => 'fffff0',
        'khaki'                => 'f0e68c',
        'lavender'             => 'e6e6fa',
        'lavenderblush'        => 'fff0f5',
        'lawngreen'            => '7cfc00',
        'lemonchiffon'         => 'fffacd',
        'lightblue'            => 'add8e6',
        'lightcoral'           => 'f08080',
        'lightcyan'            => 'e0ffff',
        'lightgoldenrodyellow' => 'fafad2',
        'lightgreen'           => '90ee90',
        'lightgray'            => 'd3d3d3',
        'lightgrey'            => 'd3d3d3',
        'lightpink'            => 'ffb6c1',
        'lightsalmon'          => 'ffa07a',
        'lightseagreen'        => '20b2aa',
        'lightskyblue'         => '87cefa',
        'lightslategray'       => '778899',
        'lightslategrey'       => '778899',
        'lightsteelblue'       => 'b0c4de',
        'lightyellow'          => 'ffffe0',
        'lime'                 => '00ff00',
        'limegreen'            => '32cd32',
        'linen'                => 'faf0e6',
        'magenta'              => 'ff00ff',
        'maroon'               => '800000',
        'mediumaquamarine'     => '66cdaa',
        'mediumblue'           => '0000cd',
        'mediumorchid'         => 'ba55d3',
        'mediumpurple'         => '9370db',
        'mediumseagreen'       => '3cb371',
        'mediumslateblue'      => '7b68ee',
        'mediumspringgreen'    => '00fa9a',
        'mediumturquoise'      => '48d1cc',
        'mediumvioletred'      => 'c71585',
        'midnightblue'         => '191970',
        'mintcream'            => 'f5fffa',
        'mistyrose'            => 'ffe4e1',
        'moccasin'             => 'ffe4b5',
        'navajowhite'          => 'ffdead',
        'navy'                 => '000080',
        'oldlace'              => 'fdf5e6',
        'olive'                => '808000',
        'olivedrab'            => '6b8e23',
        'orange'               => 'ffa500',
        'orangered'            => 'ff4500',
        'orchid'               => 'da70d6',
        'palegoldenrod'        => 'eee8aa',
        'palegreen'            => '98fb98',
        'paleturquoise'        => 'afeeee',
        'palevioletred'        => 'db7093',
        'papayawhip'           => 'ffefd5',
        'peachpuff'            => 'ffdab9',
        'peru'                 => 'cd853f',
        'pink'                 => 'ffc0cb',
        'plum'                 => 'dda0dd',
        'powderblue'           => 'b0e0e6',
        'purple'               => '800080',
        'red'                  => 'ff0000',
        'rosybrown'            => 'bc8f8f',
        'royalblue'            => '4169e1',
        'saddlebrown'          => '8b4513',
        'salmon'               => 'fa8072',
        'sandybrown'           => 'f4a460',
        'seagreen'             => '2e8b57',
        'seashell'             => 'fff5ee',
        'sienna'               => 'a0522d',
        'silver'               => 'c0c0c0',
        'skyblue'              => '87ceeb',
        'slateblue'            => '6a5acd',
        'slategray'            => '708090',
        'slategrey'            => '708090',
        'snow'                 => 'fffafa',
        'springgreen'          => '00ff7f',
        'steelblue'            => '4682b4',
        'tan'                  => 'd2b48c',
        'teal'                 => '008080',
        'thistle'              => 'd8bfd8',
        'tomato'               => 'ff6347',
        'turquoise'            => '40e0d0',
        'violet'               => 'ee82ee',
        'wheat'                => 'f5deb3',
        'white'                => 'ffffff',
        'whitesmoke'           => 'f5f5f5',
        'yellow'               => 'ffff00',
        'yellowgreen'          => '9acd32'
      }

      private

      def escape color = :black, layer = nil
        return yield unless color && colorize?
        previous_escape = Thread.current[:escape] || "\e[0m"
        escape = Thread.current[:escape] = "\e[%s%sm" % [
          layer, ANSI[color] || escape_256(color)
        ]
        [escape, yield, previous_escape].join
      ensure
        Thread.current[:escape] = previous_escape
      end

      def escape_256 color
        "8;5;#{to_256(*to_rgb(color))}" if supports_256_colors?
      end

      def supports_256_colors?
        `tput colors` =~ /256/
      end

      def to_256 r, g, b
        r, g, b = [r, g, b].map { |c| c / 10 }
        return 232 + g if r == g && g == b && g != 0 && g != 25
        16 + ((r / 5) * 36) + ((g / 5) * 6) + (b / 5)
      end

      def to_rgb hex
        n = (WEB[hex.to_s] || hex).to_i(16)
        [2, 1, 0].map { |m| n >> (m << 3) & 0xff }
      end

      def offset hex
        h, s, l = rgb_to_hsl(to_rgb(WEB[hex.to_s] || hex))
        l < 55 && !(40..80).include?(h) ? l *= 1.875 : l /= 3
        hsl_to_rgb([h, s, l]).map { |c| '%02x' % c }.join
      end

      def rgb_to_hsl rgb
        r, g, b = rgb.map { |c| c / 255.0 }
        max = [r, g, b].max
        min = [r, g, b].min
        d = max - min
        h = case max
          when min then 0
          when r   then 60 * (g - b) / d
          when g   then 60 * (b - r) / d + 120
          when b   then 60 * (r - g) / d + 240
        end
        l = (max + min) / 2.0
        s = if max == min then 0
          elsif l < 0.5   then d / (2 * l)
          else            d / (2 - 2 * l)
        end
        [h % 360, s * 100, l * 100]
      end

      def hsl_to_rgb hsl
        h, s, l = hsl
        h /= 360.0
        s /= 100.0
        l /= 100.0
        m2 = l <= 0.5 ? l * (s + 1) : l + s - l * s
        m1 = l * 2 - m2
        rgb = [[m1, m2, h + 1.0 / 3], [m1, m2, h], [m1, m2, h - 1.0 / 3]]
        rgb.map { |c|
          m1, m2, h = c
          h += 1 if h < 0
          h -= 1 if h > 1
          next m1 + (m2 - m1) * h * 6 if h * 6 < 1
          next m2 if h * 2 < 1
          next m1 + (m2 - m1) * (2.0/3 - h) * 6 if h * 3 < 2
          m1
        }.map { |c| c * 255 }
      end

      def hue_to_rgb m1, m2, h
        h += 1 if h < 0
        h -= 1 if h > 1
        return m1 + (m2 - m1) * h * 6 if h * 6 < 1
        return m2 if h * 2 < 1
        return m1 + (m2 - m1) * (2.0/3 - h) * 6 if h * 3 < 2
        return m1
      end

      def highlighter
        @highlighter ||= begin
          raise unless supports_256_colors?
          require 'pygments'
          Pygmentizer.new
        rescue
          FakePygmentizer.new
        end
      end

      class FakePygmentizer
        def highlight(code_block)
          code_block
        end
      end

      class Pygmentizer
        def initialize
          @style = ENV['GHI_HIGHLIGHT_STYLE'] || 'monokai'
        end

        def highlight(code_block)
          begin
            indent = code_block['indent']
            lang   = code_block['lang']
            code   = code_block['code']

            output = pygmentize(lang, code)
            with_indentation(output, indent)
          rescue
            code_block
          end
        end

        private

        def pygmentize(lang, code)
          Pygments.highlight(unescape(code), formatter: '256', lexer: lang,
                             options: { style: @style })
        end

        def unescape(str)
          str.gsub(/\e\[[^m]*m/, '')
        end

        def with_indentation(string, indent)
          string.each_line.map do |line|
            "#{indent}#{line}"
          end.join
        end
      end
    end
  end
end
