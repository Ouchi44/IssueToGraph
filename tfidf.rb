include Math
require "csv"
require './model/tree_tagger'

files = []
Dir.glob("comments/#{ARGV[0]}/*").each do |txt|
  files.push(txt)
end

tf = {}
target = %w(NN NNS)
i = 0

files.each do |file|
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
  rsts = tagger.analysis_file(file)

  rsts.each do |r|
    if target.include?(r[1])
      #puts r[2]
      if tf[i][r[0]].nil?
        tf[i][r[0]] = 1
      else
        tf[i][r[0]] += 1
      end
      word_count += 1
    end
  end

  tf[i].each do |word|
    tf[i][word[0]] = word[1].to_f / word_count.to_f
  end
  i += 1
end

idf = {}
tf.each do |id|
  id[1].each do |word, score|
    if idf[word].nil?
      idf[word] = 1
    else
      idf[word] += 1
    end
  end
end

idf.each do |word|
  idf[word[0]] = log(files.size.to_f / idf[word[0]].to_f, 10)
end


tfidf={}
tf.each do |id|
  tfidf[id[0]] = {}
  id[1].each do |word, score|
    tfidf[id[0]][word] = score * idf[word]
  end
end


CSV.open("outputs/#{ARGV[0]}/#{ARGV[0]}.csv", 'w') do |line|
  line << ["ID", "word1", "score1","word2", "score2","word3", "score3"]
  tfidf.each do |id|
    results = tfidf[id[0]].sort_by{|word, freq| freq}.reverse
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

similality={}
tfidf.each do |id, words|
  #results = tfidf[id[0]].sort_by{|word, freq| freq}.reverse

  similality[id] = Hash.new(0)
  tfidf.each do |id_2, words_2|
    words.each do |key, value|
      if similality[id][id_2].nil?
        similality[id][id_2] = 0
        similality[id][id_2] = value * words_2[key] unless words_2[key].nil?
      else
        similality[id][id_2] += value * words_2[key] unless words_2[key].nil?
      end
    end
    a = words.map{|k,v| v*v}.compact.inject(:+)
    b = words_2.map{|k,v| v*v}.compact.inject(:+)
    abs_a = a.nil? ? 1 : sqrt(a)
    abs_b = b.nil? ? 1 : sqrt(b)
    similality[id][id_2] = similality[id][id_2].fdiv(abs_a*abs_b)
  end
end

CSV.open("outputs/#{ARGV[0]}/similality.csv", 'w') do |line|
  line << ["ID"].concat(tfidf.map{|k,v| k})
  similality.each do |key, score|
    line << [key].concat(score.map{|k,v| v})
  end
end

CSV.open("outputs/#{ARGV[0]}/tilling.csv", 'w') do |line|
  line << ["ID","score"]
  similality.each do |key, score|
    line << ["#{key}",score[key+1]] unless score[key+1].nil?
  end
end
