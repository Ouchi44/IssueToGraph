class Comment
  attr_accessor :id, :author, :txt, :links, :tfidf, :label

  def initialize
    self.id = 0
    self.author = ''
    self.txt = ''
    self.links = []
    self.tfidf = {}
    self.label = :other
  end

  def get_chacteristic_words
    result = []
    tfidf_threshold = 0.3
    words_limit = 3

    self.tfidf.each do |word, score|
      result.push(word) if score >= tfidf_threshold
      break if result.size >= words_limit
    end
    (words_limit - result.size).times{ result.push("-") } if result.size < words_limit

    result.join(" | ")
  end

  def set_label
    arr = self.txt.to_s.split(/\s*\.|\?\s*/)
    arr.each do |sentence|
      if self.author == "hadoopqa" || self.author == "apachespark"
        return self.label = :patch
      elsif Sanitize.clean(sentence.to_s).strip.downcase.start_with?("wh") or Sanitize.clean(sentence.to_s).strip.downcase.start_with?("how")
        return self.label = :question
      elsif sentence.include?("pre class='code-")
        return self.label = :code
      elsif !self.tfidf.empty?
        self.tfidf.each do |key,val|
          return self.label = :investigative if val > 0.3
        end
      end
    end
  end

  def get_color
    # コメントラベルによって色をつける
    # patch -> ピンク
    # question -> 水色
    # code -> 灰色
    # investigative -> 黄色
    case self.label
    when :patch
      return 'pink'
    when :question
      return 'paleturquoise'
    when :code
      return 'gray'
    when :investigative
      return 'lightgoldenrod'
    else
      return 'none'
    end
  end

end
