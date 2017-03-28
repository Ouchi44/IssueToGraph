include Math
require "csv"
require './model/tree_tagger'
require 'sanitize'

class TfIdf
  attr_accessor :tf, :idf, :tfidf, :similarity

  def initialize(documents)
    @tf = calc_Tf(documents)
    @idf = calc_Idf(documents)
    @tfidf = calc_TfIdf(documents)
    @similarity = calc_TfIdf_Similarity(documents)
  end

  def calc_Tf(documents)
    # 特徴語の対象を設定する。
    # 今のとこ、名詞+固有名詞
    target = %w(NN NNS)
    i = 0
    tf = {}
    documents.each do |doc|
      tf[i] = {}
      word_count = 0
      tagger = TreeTagger.new()

      # 形態素解析の結果が配列で返ってくる
      # rsts[id][type]
      # id は解析対象のテキストIDが格納
      # type は以下の結果
      #  0 -> 解析した単語
      #  1 -> 品詞
      #  2 -> 単語の原型

      rsts = tagger.analysis(Sanitize.clean(doc.txt.to_s).strip)

      rsts.each do |r|
        if target.include?(r[1])
          if tf[i][r[2]].nil?
            tf[i][r[2]] = 1
          else
            tf[i][r[2]] += 1
          end
          word_count += 1
        end
      end

      tf[i].each do |word|
        tf[i][word[0]] = word[1].to_f / word_count.to_f
      end
      i += 1
    end
    return tf
  end

  def calc_Idf(documents)
    idf = {}
    @tf.each do |id|
      id[1].each do |word, score|
        if idf[word].nil?
          idf[word] = 1
        else
          idf[word] += 1
        end
      end
    end

    idf.each do |word|
      idf[word[0]] = log(documents.size.to_f / idf[word[0]].to_f, 10)
    end

    return idf
  end


  def calc_TfIdf(documents)
    tfidf = {}
    sorted_tfidf = {}
    @tf.each do |id, scores|
      tfidf[id] = {}
      scores.each do |word, score|
        tfidf[id][word] = score * @idf[word]
      end
    end
    tfidf.each do |id, scores|
      sorted_tfidf[id] = Hash[scores.sort_by{|word, freq| freq}.reverse]
    end

    return sorted_tfidf
  end

  def calc_TfIdf_Similarity(documents)
    similarity = {}
    @tfidf.each do |id, words|
      #results = tfidf[id[0]].sort_by{|word, freq| freq}.reverse

      similarity[id] = Hash.new(0)
      @tfidf.each do |id_2, words_2|
        words.each do |key, value|
          if similarity[id][id_2].nil?
            similarity[id][id_2] = 0
            similarity[id][id_2] = value * words_2[key] unless words_2[key].nil?
          else
            similarity[id][id_2] += value * words_2[key] unless words_2[key].nil?
          end
        end
        a = words.map{|k,v| v*v}.compact.inject(:+)
        b = words_2.map{|k,v| v*v}.compact.inject(:+)
        abs_a = a.nil? ? 1 : sqrt(a)
        abs_b = b.nil? ? 1 : sqrt(b)
        similarity[id][id_2] = similarity[id][id_2].fdiv(abs_a*abs_b)
      end
    end

    return similarity
  end

  def save_tfidf(dir_name)
    CSV.open("outputs/#{dir_name}/tfidf.csv", 'w') do |line|
      line << ["ID", "word1", "score1","word2", "score2","word3", "score3"]
      self.tfidf.each do |id|
        results = self.tfidf[id[0]].sort_by{|word, freq| freq}.reverse
        #puts "ID #{id[0]}"
        if results[0].nil?
          line << [id[0], "-","-","-","-","-","-"]
        elsif results[1].nil?
          line << [id[0], results[0][0],"-","-","-","-" ]
        elsif results[2].nil?
          line << [id[0], results[0][0], results[0][1],results[1][0], results[1][1],"-","-"]
        else
          line << [id[0], results[0][0], results[0][1],results[1][0], results[1][1],results[2][0], results[2][1]]
        end
      end
    end
  end

  def save_similarity(dir_name)
    CSV.open("outputs/#{dir_name}/similarity.csv", 'w') do |line|
      line << ["ID"].concat(tfidf.map{|k,v| k})
      self.similarity.each do |key, score|
        line << [key].concat(score.map{|k,v| v})
      end
    end
  end

  def save_tiling(dir_name)
    CSV.open("outputs/#{dir_name}/tilling.csv", 'w') do |line|
      line << ["ID","score"]
      self.similarity.each do |key, score|
        line << ["#{key}",score[key+1]] unless score[key+1].nil?
      end
    end
  end

end
