module GHI
  module Commands
    module EditorTool
      def extract_labels_from_message(message)
        words = message.split
        hashtags = words.select { |word| word.start_with?("#") }
        new_message = (words - hashtags).join(" ")
        message.replace(new_message)

        return labels = hashtags.map! { |label| label[1..-1] }
      end
    end
  end
end
